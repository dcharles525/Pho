project ('com.github.dcharles525.pho', 'vala', 'c')

i18n = import('i18n')
gnome = import ('gnome')

asresources = gnome.compile_resources(
  'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')
add_global_arguments ('-DGETTEXT_PACKAGE="' + meson.project_name () + '"', language:'c')

i18n.merge_file(
  input: join_paths('data', meson.project_name() + '.desktop'),
  output: meson.project_name() + '.desktop',
  po_dir: join_paths(meson.source_root(), 'po'),
  type: 'desktop',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

#Translate and install our .appdata file
i18n.merge_file(
  input: join_paths('data', meson.project_name() + '.appdata.xml'),
  output: meson.project_name() + '.appdata.xml',
  po_dir: join_paths(meson.source_root(), 'po'),
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

executable(
    meson.project_name(),
    'src/Pho.vala',
    'src/Thread.vala',
    'src/Posts.vala',
    'src/Replies.vala',
    'src/VideoPlayer.vala',
    asresources,
    dependencies: [
      dependency('gtk+-3.0'),
      dependency('libsoup-2.4'),
      dependency('json-glib-1.0'),
      dependency('webkit2gtk-4.0'),
      dependency('gee-0.8'),
      dependency('gstreamer-1.0'),
      dependency('clutter-gst-3.0'),
      dependency('clutter-gtk-1.0'),
      dependency('granite')
    ],
    install: true
)

subdir ('po')
