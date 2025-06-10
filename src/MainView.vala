/*
 *  Copyright (C) 2020 Darshak Parikh
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *  Authored by: Darshak Parikh <darshak@protonmail.com>
 *
 */

public class Obliviate.MainView : Gtk.Box {
    private Gtk.Overlay overlay;
    private Gtk.Grid grid;
    private Granite.Toast toast;

    private Gtk.Entry site;
    private Gtk.PasswordEntry cipher_key;
    private Gtk.PasswordEntry generated_pass;
    private Gtk.Button copy_btn;
    private Gtk.Button copy_without_symbols_btn;
    private Gtk.Label clearing_label;
    private Gtk.ProgressBar clearing_progress;

    private Gdk.Clipboard clipboard;
    private const float CLIPBOARD_LIFE = 30;
    private uint timeout_id;

    construct {
        overlay = new Gtk.Overlay () {
            hexpand = true,
            vexpand = true
        };

        grid = new Gtk.Grid () {
            row_spacing = 4,
            column_spacing = 4,
            margin_top = 30,
            margin_bottom = 30,
            margin_start = 18,
            margin_end = 18,
            halign = Gtk.Align.CENTER
        };

        var toast = new Granite.Toast (_ ("Copied to clipboard"));

        overlay.set_child (grid);
        overlay.add_overlay (toast);

        var site_label = new Gtk.Label (_ ("Site:")) {
            halign = Gtk.Align.END,
            margin_end = 4
        };

        site = new Gtk.Entry () {
            placeholder_text = _ ("GitHub"),
            primary_icon_name = "dialog-information-symbolic",
            primary_icon_tooltip_text = "Site is not case-sensitive. “GitHub” equals “github”."
        };

        site.changed.connect (handle_generate_password);

        var cipher_key_label = new Gtk.Label (_ ("Cipher key:")) {
            halign = Gtk.Align.END,
            margin_end = 4
        };

        cipher_key = new Gtk.PasswordEntry () {
            show_peek_icon = true,
            placeholder_text = _ ("correct horse battery staple"),
            width_chars = 24
        };

        cipher_key.changed.connect (handle_generate_password);

        this.generated_pass = new Gtk.PasswordEntry () {
            show_peek_icon = true,
            editable = false,
            width_chars = 24
        };

        copy_btn = new Gtk.Button.with_label (_ ("Copy")) {
            sensitive = false,
            hexpand = true
        };

        copy_btn.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        copy_btn.clicked.connect (() => {
            handle_copy ();
        });

        copy_without_symbols_btn = new Gtk.Button.with_label (_ ("Copy without symbols")) {
            sensitive = false
        };

        copy_without_symbols_btn.clicked.connect (() => {
            handle_copy (true);
        });

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            margin_top = 4
        };

        button_box.append (copy_btn);
        button_box.append (copy_without_symbols_btn);

        clearing_label = new Gtk.Label (ngettext (
            "Clearing clipboard in %.0f second",
            "Clearing clipboard in %.0f seconds",
            (ulong) CLIPBOARD_LIFE
        ).printf (CLIPBOARD_LIFE)) {
            margin_top = 18,
            halign = Gtk.Align.START,
            hexpand = false
        };

        clearing_progress = new Gtk.ProgressBar () {
            fraction = 1
        };

        clearing_progress.add_css_class (Granite.STYLE_CLASS_FLAT);

        var plus_label = new Gtk.Label ("+");
        plus_label.add_css_class ("sign");

        var equals_label = new Gtk.Label ("=");
        equals_label.add_css_class ("sign");

        grid.attach (site_label, 0, 0, 1, 1);
        grid.attach_next_to (site, site_label, Gtk.PositionType.RIGHT);

        grid.attach_next_to (plus_label, site, Gtk.PositionType.BOTTOM);

        grid.attach (cipher_key_label, 0, 2, 1, 1);
        grid.attach_next_to (cipher_key, cipher_key_label, Gtk.PositionType.RIGHT);

        grid.attach_next_to (equals_label, cipher_key, Gtk.PositionType.BOTTOM);

        grid.attach_next_to (generated_pass, equals_label, Gtk.PositionType.BOTTOM);
        grid.attach_next_to (button_box, generated_pass, Gtk.PositionType.BOTTOM);

        clipboard = this.get_clipboard ();

        append (overlay);
    }

    private void handle_generate_password () {
        if (site.text.length == 0 || cipher_key.text.length == 0) {
            generated_pass.text = "";
            copy_btn.sensitive = false;
            copy_without_symbols_btn.sensitive = false;
            return;
        }

        try {
            generated_pass.text = Service.derive_password (cipher_key.text, site.text.down ());
            copy_btn.sensitive = true;
            copy_without_symbols_btn.sensitive = true;
            animate_password ();
        } catch (CryptoError error) {
            toast.title = _ ("Could not derive password");
            toast.send_notification ();
        }
    }

    private void handle_copy (bool ignore_symbols = false) {
        Source.remove (timeout_id);

        var text_to_copy = ignore_symbols
            ? Service.remove_symbols (generated_pass.text)
            : generated_pass.text;

        clipboard.set_text (text_to_copy);

        toast.title = _ ("Copied to clipboard");
        toast.send_notification ();

        show_clearing_widgets ();

        float seconds_left = CLIPBOARD_LIFE;
        timeout_id = Timeout.add_seconds (1, () => {
            if (seconds_left == 0) {
                clipboard.set_text ("");

                toast.title = _ ("Cleared the clipboard");
                toast.send_notification ();

                hide_clearing_widgets ();
                return false;
            }

            seconds_left--;
            clearing_label.label = ngettext (
                "Clearing clipboard in %.0f second",
                "Clearing clipboard in %.0f seconds",
                (ulong) seconds_left
            ).printf (seconds_left);
            clearing_progress.fraction = seconds_left / CLIPBOARD_LIFE;

            return true;
        });
    }

    private void show_clearing_widgets () {
        if (grid.get_child_at (1, 6) != clearing_label) {
            grid.attach (clearing_label, 1, 6, 1, 1);
            grid.attach_next_to (clearing_progress, clearing_label, Gtk.PositionType.BOTTOM);
        }

        clearing_label.visible = true;
        clearing_progress.visible = true;
    }

    private void hide_clearing_widgets () {
        clearing_label.visible = false;
        clearing_progress.visible = false;
    }

    private void animate_password () {
        generated_pass.add_css_class ("regenerating");
        Timeout.add (100, () => {
            generated_pass.remove_css_class ("regenerating");
            return false;
        });
    }
}
