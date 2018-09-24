project ('com.github.dcharles525.pho', 'vala', 'c')

gnome = import ('gnome')

asresources = gnome.compile_resources(
  'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

add_global_arguments ('-DGETTEXT_PACKAGE="' + meson.project_name () + '"', language:'c')

executable(
    meson.project_name(),
    'src/Pho.vala',
    'src/Thread.vala',
    'src/Posts.vala',
    asresources,
    dependencies: [
      dependency('gtk+-3.0'),
      dependency('libsoup-2.4'),
      dependency('json-glib-1.0'),
      dependency('webkit2gtk-4.0'),
      dependency('gee-0.8'),
      dependency('gstreamer-1.0')
    ],
    install: true
)

subdir ('data')
