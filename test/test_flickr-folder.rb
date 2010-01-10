require 'helper'

class TestFlickrFolder < Test::Unit::TestCase

  context "The creation of a FlikrFolder" do
    should "fail if there is no option hash specified." do
      assert_raise ArgumentError do
        FlickrFolder.new
      end
    end
    should "fail if there is no :search option specified" do
      assert_raise ArgumentError do
        FlickrFolder.new({ :folder => 'tmp/photos' })
      end
    end
    should "fail if there is no :folder option specified" do
      assert_raise ArgumentError do
        FlickrFolder.new({ :search => 'miami beach' })
      end
    end
  end

  @@purged_once = false
  context "A FlickrFolder" do
    setup do
      FileUtils::rm_rf('tmp') unless @@purged_once; @@purged_once = true
      @folder = FlickrFolder.new({
        :config => 'config/flickr.yml',
        :folder => {
          :path => 'tmp/photos',
          :number => 3,
          :minimum_resolution => 1000
        },
        :search => {
          :tags => 'miami beach',
          :sort => 'interestingness-desc'
        }
      })
    end
    should "00 find photos after a search for a known positive" do
      assert_not_nil @folder
      @folder.update
      assert_equal 3, @folder.photo_count
    end
    should "01 purge photos" do
      assert_not_nil @folder
      assert_equal 3, @folder.photo_count
      @folder.purge_photos 2
      assert_equal 1, @folder.photo_count
    end
    should "02 find more photos after a few are deleted" do
      assert_not_nil @folder
      assert_equal 1, @folder.photo_count
      @folder.update
      assert_equal 3, @folder.photo_count
    end
  end

  context "A filtered FlickrFolder" do
    setup do
      FileUtils::rm_rf('tmp')
      @folder = FlickrFolder.new({
        :config => 'config/flickr.yml',
        :folder => {
          :path => 'tmp/photos',
          :number => 3,
          :minimum_resolution => 100
        },
        :search => {
          :tags => 'miami beach',
          :sort => 'interestingness-desc'
        },
        :filter => Proc.new do |photo|
          true if photo.id.slice(0,1).eql? '1'
        end
      })
    end
    should "only download files that match the filter" do
      assert_not_nil @folder
      @folder.update
      assert_equal 3, @folder.photo_count
      @folder.photo_files.each do |photo_file|
        assert_equal '1', photo_file.slice(0,1)
      end
    end
  end
end
