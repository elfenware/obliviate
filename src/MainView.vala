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

public class Obliviate.MainView : Gtk.Overlay {
    private Gtk.Grid grid;
    private Granite.Toast toast;

    private Gtk.Entry site;
    private Gtk.Entry cipher_key;
    private Gtk.Entry generated_pass;
    private Gtk.ToggleButton show_generated_pass;
    private Gtk.Button copy_btn;
    private Gtk.Button copy_without_symbols_btn;
    private Gtk.Label clearing_label;
    private Gtk.ProgressBar clearing_progress;

    private Gdk.Clipboard clipboard;
    private const float CLIPBOARD_LIFE = 30;
    private uint timeout_id;

    construct {
        grid = new Gtk.Grid () {
            row_spacing = 4,
            column_spacing = 4,
            margin = 30,
            halign = Gtk.Align.CENTER
        };

        toast = new Granite.Widgets.Toast (_ ("Copied to clipboard"));

        add (grid);
        add_overlay (toast);

        var site_label = new Gtk.Label (_ ("Site:")) {
            halign = Gtk.Align.END,
            margin_end = 4
        };

        site = new Gtk.Entry () {
            placeholder_text = _ ("GitHub")
        };

        site.changed.connect (handle_generate_password);

        var site_info = new Gtk.Image.from_icon_name ("dialog-information-symbolic", Gtk.IconSize.MENU) {
            tooltip_text = _ ("Site is not case-sensitive. “GitHub” equals “github”.")
        };

        var cipher_key_label = new Gtk.Label (_ ("Cipher key:")) {
            halign = Gtk.Align.END,
            margin_end = 4
        };

        // TODO: replace with Gtk.PasswordEntry after updating to Gtk4
        cipher_key = new Gtk.Entry () {
            visibility = false,
            caps_lock_warning = true,
            input_purpose = Gtk.InputPurpose.PASSWORD,
            placeholder_text = _ ("correct horse battery staple"),
            width_chars = 24
        };

        cipher_key.changed.connect (handle_generate_password);

        var show_cipher_key = new Gtk.ToggleButton () {
            active = true,
            tooltip_text = _ ("Show or hide the cipher key")
        };

        show_cipher_key.add (new Gtk.Image.from_icon_name ("image-red-eye-symbolic", Gtk.IconSize.BUTTON));
        show_cipher_key.bind_property ("active", cipher_key, "visibility", BindingFlags.INVERT_BOOLEAN);

        generated_pass = new Gtk.Entry () {
            visibility = false,
            editable = false,
            sensitive = false
        };

        generated_pass.add_css_class (Granite.STYLE_CLASS_FLAT);

        show_generated_pass = new Gtk.ToggleButton () {
            active = true,
            tooltip_text = _ ("Show or hide the password"),
            sensitive = false
        };

        show_generated_pass.add (new Gtk.Image.from_icon_name ("image-red-eye-symbolic", Gtk.IconSize.BUTTON));
        show_generated_pass.bind_property ("active", generated_pass, "visibility", BindingFlags.INVERT_BOOLEAN);

        copy_btn = new Gtk.Button.with_label (_ ("Copy")) {
            sensitive = false
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

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
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
        grid.attach_next_to (site_info, site, Gtk.PositionType.RIGHT);

        grid.attach_next_to (plus_label, site, Gtk.PositionType.BOTTOM);

        grid.attach (cipher_key_label, 0, 2, 1, 1);
        grid.attach_next_to (cipher_key, cipher_key_label, Gtk.PositionType.RIGHT);
        grid.attach_next_to (show_cipher_key, cipher_key, Gtk.PositionType.RIGHT);

        grid.attach_next_to (equals_label, cipher_key, Gtk.PositionType.BOTTOM);

        grid.attach_next_to (generated_pass, equals_label, Gtk.PositionType.BOTTOM);
        grid.attach_next_to (show_generated_pass, generated_pass, Gtk.PositionType.RIGHT);
        grid.attach_next_to (button_box, generated_pass, Gtk.PositionType.BOTTOM);

        clipboard = Gdk.Display.get_default ().get_clipboard ();
    }

    private void handle_generate_password () {
        if (site.text.length == 0 || cipher_key.text.length == 0) {
            generated_pass.text = "";
            show_generated_pass.sensitive = false;
            copy_btn.sensitive = false;
            copy_without_symbols_btn.sensitive = false;
            return;
        }

        try {
            generated_pass.text = Service.derive_password (cipher_key.text, site.text.down ());
            show_generated_pass.sensitive = true;
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
        var password_style = generated_pass.get_style_context ();
        password_style.add_class ("regenerating");
        Timeout.add (100, () => {
            password_style.remove_class ("regenerating");
            return false;
        });
    }
}
