# Project name, programming language and version
project (
    'com.github.elfenware.obliviate',
    'vala', 'c',
    version: '2.0.0'
)

# Translation module
i18n = import ('i18n')

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
    dependency ('granite'),
    dependency ('gtk+-3.0'),
    declare_dependency (dependencies: [
        meson.get_compiler ('c').find_library ('libgcrypt'),
        meson.get_compiler ('vala').find_library ('gcrypt', dirs: join_paths (meson.current_source_dir (), 'vapi'))
    ])
]

subdir ('src')

# Executable
executable (
    meson.project_name (),
    asresources,
    sources,
    dependencies: dependencies,
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script ('meson/post_install.py')
