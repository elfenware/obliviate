# Project name, programming language and version
project (
    'com.github.elfenware.obliviate',
    'vala', 'c',
    version: '3.0.0'
)

# Translation module
i18n = import ('i18n')

# Translations data
config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

# GNOME module
gnome = import('gnome')

# Project arguments
add_project_arguments (
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
    language: 'c'
)

# Compiling resources
asresources = gnome.compile_resources (
    'as-resources',
    join_paths ('data', meson.project_name ()) + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Listing dependencies
dependencies = [
    dependency ('glib-2.0'),
    dependency ('granite-7'),
    dependency ('gtk4'),
    dependency ('libhandy-1'),
    declare_dependency (dependencies: [
        meson.get_compiler ('c').find_library ('libgcrypt'),
        meson.get_compiler ('vala').find_library ('gcrypt', dirs: join_paths (meson.current_source_dir (), 'vapi'))
    ])
]

subdir ('src')

# Executable
executable (
    meson.project_name (),
    config_file,
    asresources,
    sources,
    dependencies: dependencies,
    install: true
)

subdir('data')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true
  )
