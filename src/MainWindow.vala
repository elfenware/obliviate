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

public class Obliviate.MainWindow : Gtk.Window {
    private GLib.Settings settings;

    public MainWindow (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        var header = get_header ();

        var main = new MainView ();

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.add (header);
        box.add (main);
        set_child (box);

        set_size_request (440, 280);

        settings = new GLib.Settings ("com.github.elfenware.obliviate.state");

        set_default_size (settings.get_int ("window-width"), settings.get_int ("window-height"));

        show ();

        this.close_request.connect (e => {
            return before_destroy ();
        });
    }

    private Hdy.HeaderBar get_header () {
        var header = new Hdy.HeaderBar () {
            title = "Obliviate",
            has_subtitle = false,
            show_close_button = true
        };

        header.add_css_class (Gtk.STYLE_CLASS_FLAT);
        header.add_css_class ("headerbar");

        var help_btn = new Gtk.Button.from_icon_name ("help-contents") {
            tooltip_text = _("Help and FAQ")
        };

        help_btn.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/elfenware/obliviate/wiki/Help-and-FAQ", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        header.pack_end (help_btn);

        return header;
    }

    private bool before_destroy () {
        int width, height;

        get_default_size (out width, out height);

        settings.set_int ("window-width", width);
        settings.set_int ("window-height", height);

        return false;
    }
}
