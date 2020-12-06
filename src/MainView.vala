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
    private Gtk.Button generate_btn;
    private Gtk.Label generated_pass_label;
    private Gtk.Entry generated_pass;
    private Gtk.ToggleButton show_generated_pass;
    private Gtk.Button copy_btn;

    private Gtk.Clipboard clipboard;

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
            margin_right = 4
        };

        site = new Gtk.Entry ();
        site.changed.connect (validate);

        var cipher_key_label = new Gtk.Label (_ ("Cipher key:")) {
            halign = Gtk.Align.END,
            margin_right = 4
        };

        // TODO: replace with Gtk.PasswordEntry after updating to Gtk4
        cipher_key = new Gtk.Entry () {
            visibility = false,
            caps_lock_warning = true,
            input_purpose = Gtk.InputPurpose.PASSWORD
        };

        cipher_key.changed.connect (validate);

        var show_cipher_key = new Gtk.ToggleButton () {
            active = true,
            tooltip_text = _ ("Show or hide the cipher key")
        };

        show_cipher_key.add (new Gtk.Image.from_icon_name ("image-red-eye-symbolic", Gtk.IconSize.BUTTON));
        show_cipher_key.bind_property ("active", cipher_key, "visibility", BindingFlags.INVERT_BOOLEAN);

        generate_btn = new Gtk.Button.with_label (_ ("Derive Password")) {
            sensitive = false,
            margin_bottom = 24
        };

        generate_btn.clicked.connect (handle_generate_password);

        generated_pass_label = new Gtk.Label (_ ("Password:")) {
            halign = Gtk.Align.END,
            margin_right = 4,
            sensitive = false
        };

        generated_pass = new Gtk.Entry () {
            visibility = false,
            editable = false,
            sensitive = false
        };

        generated_pass.get_style_context ().add_class ("flat");

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
        copy_btn.clicked.connect (handle_copy);

        grid.attach (site_label, 0, 0, 1, 1);
        grid.attach_next_to (site, site_label, Gtk.PositionType.RIGHT);

        grid.attach (cipher_key_label, 0, 1, 1, 1);
        grid.attach_next_to (cipher_key, cipher_key_label, Gtk.PositionType.RIGHT);
        grid.attach_next_to (show_cipher_key, cipher_key, Gtk.PositionType.RIGHT);

        grid.attach_next_to (generate_btn, cipher_key, Gtk.PositionType.BOTTOM);

        grid.attach (generated_pass_label, 0, 4, 1, 1);
        grid.attach (generated_pass, 1, 4, 1, 1);
        grid.attach_next_to (show_generated_pass, generated_pass, Gtk.PositionType.RIGHT);

        grid.attach_next_to (copy_btn, generated_pass, Gtk.PositionType.BOTTOM);

        clipboard = Gtk.Clipboard.get_default (Gdk.Display.get_default ());
    }

    private void handle_generate_password () {
        // TODO: make site case insensitive
        var derived_password = Crypto.derive_password (cipher_key.text, site.text);
        generated_pass.text = derived_password;

        generated_pass_label.sensitive = true;
        show_generated_pass.sensitive = true;
        copy_btn.sensitive = true;

        copy_btn.is_focus = true;
    }

    private void handle_copy () {
        clipboard.set_text (generated_pass.text, generated_pass.text.length);
        toast.send_notification ();
    }

    private void validate () {
        generate_btn.sensitive = site.text.length > 0 && cipher_key.text.length > 0;
    }
}
