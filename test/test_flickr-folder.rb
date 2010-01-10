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
        :verbose => true,
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
    should "find photos after a search for a known positive." do
      assert_not_nil @folder
      count = @folder.update
      assert_equal 3, count
    end
    should "find more photos after a few are deleted." do
      assert_not_nil @folder
      count = @folder.update
      assert_equal 3, count
    end
  end
  
end
