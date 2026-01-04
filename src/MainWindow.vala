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
    public MainWindow (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        var headerbar = get_headerbar ();

        var main = new MainView ();

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (main);
        set_child (box);

        set_titlebar (headerbar);

        set_size_request (440, 280);

        show ();
    }

    private Gtk.HeaderBar get_headerbar () {
        set_title (_("Obliviate"));
        Gtk.Label title_widget = new Gtk.Label (_("Obliviate"));
        title_widget.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var headerbar = new Gtk.HeaderBar ();
        headerbar.set_title_widget (title_widget);
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

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

        headerbar.pack_end (help_btn);

        return headerbar;
    }
}
