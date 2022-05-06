# Derivativo

Derivativo is derivative generation app that converts images, audio, video, office documents, and PDFs.  This app provides media file processing functionality for [Hyacinth](https://github.com/cul/ldpd-hyacinth).

## Requirements

- Ruby 3.0
- Redis 3
- ffmpeg (tested with version 4)
- libvips (tested with version 8.8)
- Apache Tika (tested with version 1.25)
- LibreOffice, for the `soffice` binary (tested with version 6)

## First-Time Setup (for developers)

```
git clone git@github.com:cul/ren-derivativo.git # Clone the repo
cd ren-derivativo # Switch to the application directory
# Note: Make sure rvm has selected the correct ruby version. You may need to cd out of the directory and then cd back into it force rvm to use the ruby version specified in .ruby_version.
bundle install # Install gem dependencies
yarn install # this assumes you have node and yarn installed (tested with Node 8 and Node 10)
bundle exec rake derivativo:setup:config_files # Set up config files like redis.yml, resque.yml, and derivativo.yml
bundle exec rake db:migrate # Run database migrations
bundle exec rake derivativo:setup:default_users # Set up default Derivativo users
rails s -p 3000 # Start the application using rails server
```
And for faster React app recompiling during development, run this in a separate terminal window:

```
./bin/webpack-dev-server
```

Note that some features (and the test suite) won't run properly if you don't have all of the dependent programs installed.  Take a look at the Requirements section near the top of this README for the full list.  In most cases it's easiest to install requirements using a package manager (Homebrew on a Mac, apt/yum on Linux, etc.) and they'll be placed on your path automatically.  If you install dependent programs in a way that doesn't put them on your path, you can specify the path in `config/derivativo.yml`:

```
ffmpeg_binary_path: '/path/to/ffmpeg'
ffmpeg_binary_path: '/path/to/ffprobe'
ghostscript_binary_path: '/path/to/gs'
```

Make sure not to set the above overrides if you want to use the binary on your path.

Note that the Tika jar location always needs to be specified in `config/derivativo.yml` because it's not a standalone executable like other binaries and needs to be run with the `java -jar` command:

```
tika_jar_path: '/Applications/tika/tika-app-2.4.0.jar'
```

And depending on how you install LibreOffice, the internal office binary may not be on your path and you may need to specify the location in `config/derivativo.yml`.  On a standalone Mac installation of LibreOffice, you'd need to set the soffice_binary_path like this:
```
soffice_binary_path: '/Applications/LibreOffice.app/Contents/MacOS/soffice'
```
But once again, omit this override if you want to refer to the version on your path.

## Development Notes

There's an important thing that appears in a bunch of files:
```
Derivativo::FileHelper.block_until_file_exists(path_to_file)
```
At Columbia, we're running a lot of things on network-mounted disks and there's sometimes a delay between when a file is written and when that same file is actually readable on disk.  We use the above method to wait for a just-written file to appear. And don't worry -- there's a wait timeout!

## Testing
Our testing suite runs Rubocop and then runs all of our ruby tests. Travis CI will automatically run the test suite for every commit and pull request.

To run the continuous integration test suite locally on your machine run:
```
bundle exec rake derivativo:ci
```

## Attribution

`spec/fixtures/file/image.jpg` is derived from from creative commons file: https://www.pexels.com/photo/grey-and-white-long-coated-cat-in-middle-of-book-son-shelf-156321/

`spec/fixtures/file/audio.wav` is derived from Creative Commons file: https://commons.wikimedia.org/wiki/File:Rafael_Krux_-_Uplifting_Blockbuster_(cc-by)_(filmmusic).mp3

`spec/fixtures/file/video.mp4` is derived from Creative Commons short film: https://peach.blender.org/
