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
    private Granite.Widgets.Toast toast;

    private Gtk.Entry site;
    private Gtk.Entry cipher_key;
    private Gtk.Entry generated_pass;
    private Gtk.ToggleButton show_generated_pass;
    private Gtk.Button copy_btn;
    private Gtk.Label clearing_label;
    private Gtk.ProgressBar clearing_progress;

    private Gtk.Clipboard clipboard;
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

        add_overlay (grid);
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
            sensitive = false,
            margin_top = 30
        };

        generated_pass.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        show_generated_pass = new Gtk.ToggleButton () {
            active = true,
            tooltip_text = _ ("Show or hide the password"),
            margin_top = 30
        };

        show_generated_pass.add (new Gtk.Image.from_icon_name ("image-red-eye-symbolic", Gtk.IconSize.BUTTON));
        show_generated_pass.bind_property ("active", generated_pass, "visibility", BindingFlags.INVERT_BOOLEAN);

        copy_btn = new Gtk.Button.with_label (_ ("Copy"));
        copy_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        copy_btn.clicked.connect (handle_copy);

        clearing_label = new Gtk.Label (_ ("Clearing clipboard in %.0f seconds").printf (CLIPBOARD_LIFE)) {
            margin_top = 18,
            halign = Gtk.Align.START,
            hexpand = false
        };

        clearing_progress = new Gtk.ProgressBar () {
            fraction = 1
        };

        clearing_progress.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        grid.attach (site_label, 0, 0, 1, 1);
        grid.attach_next_to (site, site_label, Gtk.PositionType.RIGHT);
        grid.attach_next_to (site_info, site, Gtk.PositionType.RIGHT);

        grid.attach (cipher_key_label, 0, 1, 1, 1);
        grid.attach_next_to (cipher_key, cipher_key_label, Gtk.PositionType.RIGHT);
        grid.attach_next_to (show_cipher_key, cipher_key, Gtk.PositionType.RIGHT);

        clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());
    }

    private void handle_generate_password () {
        if (site.text.length == 0 || cipher_key.text.length == 0) {
            hide_password_widgets ();
            return;
        }

        try {
            generated_pass.text = Crypto.derive_password (cipher_key.text, site.text.down ());
            show_password_widgets ();
            animate_password ();
        } catch (CryptoError error) {
            toast.title = _ ("Could not derive password");
            toast.send_notification ();
        }
    }

    private void handle_copy () {
        Source.remove (timeout_id);
        clipboard.set_text (generated_pass.text, generated_pass.text.length);

        toast.title = _ ("Copied to clipboard");
        toast.send_notification ();

        show_clearing_widgets ();

        float seconds_left = CLIPBOARD_LIFE;
        timeout_id = Timeout.add_seconds (1, () => {
            if (seconds_left == 0) {
                clipboard.clear ();

                toast.title = _ ("Cleared the clipboard");
                toast.send_notification ();

                hide_clearing_widgets ();
                return false;
            }

            seconds_left--;
            clearing_label.label = _ ("Clearing clipboard in %.0f seconds").printf (seconds_left);
            clearing_progress.fraction = seconds_left / CLIPBOARD_LIFE;

            return true;
        });
    }

    private void show_password_widgets () {
        if (grid.get_child_at (1, 4) != generated_pass) {
            grid.attach (generated_pass, 1, 4, 1, 1);
            grid.attach_next_to (show_generated_pass, generated_pass, Gtk.PositionType.RIGHT);
            grid.attach_next_to (copy_btn, generated_pass, Gtk.PositionType.BOTTOM);
        }

        generated_pass.visible = true;
        show_generated_pass.show_all ();
        copy_btn.visible = true;
    }

    private void hide_password_widgets () {
        generated_pass.visible = false;
        show_generated_pass.visible = false;
        copy_btn.visible = false;
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
