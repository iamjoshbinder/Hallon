require 'lib/hallon'
require File.expand_path('../config', __FILE__)

Dir.chdir(File.dirname(__FILE__))

# Globals
TRACK_URI = "spotify:track:4yJmwG2C1SDgcBbV50xI91"
TRACK_URI2 = "spotify:track:5st5644IlBmKiiRE73UsoZ"
PLAYLIST_URI = "spotify:user:burgestrand:playlist:4MsjQL7fkrtfWAOyV5Rnwa"
PLAYLIST  = "rspec-" + Time.now.gmtime.strftime("%Y-%m-%d %H:%M:%S.#{Time.now.gmtime.usec}")

describe Hallon do
  it "has an up-to-date spotify library" do
    Hallon::API_VERSION.should == 4
  end
end

describe Hallon::Session, " before creation" do
  it "should be a singleton" do
    Hallon::Session.should_not respond_to(:new)
  end

  it "should require an application key" do
    lambda { Hallon::Session.instance }.should raise_error(ArgumentError)
  end

  it "should fail on an invalid application key" do
    lambda { Hallon::Session.instance('invalid') }.should raise_error(Hallon::Error)
  end
  
  it "should succeed with a valid application key" do
    lambda { Hallon::Session.instance APPKEY }.should_not raise_error
  end
end

describe Hallon::Session, " once created" do
  before :all do
    @session = Hallon::Session.instance
  end
  
  it "should not be logged in" do
    @session.logged_in?.should equal false
  end
  
  it "can log in" do
    @session.logged_in?.should equal false
    @session.login(USERNAME, PASSWORD)
    @session.logged_in?.should equal true
  end
  
  it "can log out" do
    @session.logged_in?.should equal true
    @session.logout
    @session.logged_in?.should equal false
  end
end

describe Hallon::PlaylistContainer do
  before :all do
    @session = Hallon::Session.instance.login(USERNAME, PASSWORD)
    @session.logged_in?.should equal true
    @container = @session.playlists
  end
  
  after :all do
    @session.logout
  end
  
  it "should validate playlist name length before creation" do
    # 0 < x < 256
    lambda { @container.add! "" }.should raise_error(ArgumentError)
    lambda { @container.add!("a" * 256) }.should raise_error(ArgumentError)
  end
  
  it "should validate playlist name contents before creation" do
    # Not only spaces
    lambda { @container.add! " " }.should raise_error(ArgumentError)
  end
  
  it "can create new playlists" do
    length = @container.length
    playlist = @container.add! PLAYLIST
    @container.length.should equal length + 1
    playlist.name.should == PLAYLIST
  end
  
  it "can remove playlists" do
    length = @container.length
    playlist = @container.detect { |a| a.name == PLAYLIST }
    playlist.should_not equal nil
    @container.remove! playlist
    @container.length.should equal length - 1
  end
  
  it "can lookup playlists by position" do
    @container.at([0, @container.length - 1].max).name.should == @container.at(-1).name
  end
end

describe Hallon::Playlist do
  before :all do
    @session = Hallon::Session.instance.login(USERNAME, PASSWORD)
    @session.logged_in?.should equal true
    @playlist = @session.playlists.add! PLAYLIST
  end
  
  after :all do
    @session.playlists.remove! @playlist
    @session.logout
  end
  
  it "can be spawned from a link" do
    Hallon::Link.new(PLAYLIST_URI).to_obj.class.should equal Hallon::Playlist
  end
  
  it "should not respond to #new" do
    lambda { Hallon::Playlist.new }.should raise_error
  end
  
  it "should have a length of 0" do
    @playlist.length.should be 0
  end
  
  it "should be loaded" do
    @playlist.loaded?.should equal true
  end
  
  it "should have a link" do
    link = @playlist.link
    link.to_str.should match "^spotify:(.*?):playlist:"
    link.type.should equal :playlist
  end
  
  it "can set collaboration flag" do
    @playlist.collaborative?.should equal false
    @playlist.collaborative = true
    @playlist.collaborative?.should equal true
  end
  
  it "can add new tracks" do
    track1 = Hallon::Link.new(TRACK_URI).to_obj
    length = @playlist.length
    @playlist.insert! 0, track1, track1
    @playlist.length.should equal length + 2
  end

  it "should enforce a valid position when adding tracks" do
    lambda { @playlist.insert! @playlist.length + 1, Hallon::Link.new(TRACK_URI).to_obj }.should raise_error(ArgumentError)
  end
  
  it "can not add non-tracks" do
    lambda { @playlist.insert! 0, @session }.should raise_error(TypeError)
  end
  
  it "can lookup tracks by position" do
    @playlist.at(0).name.should == Hallon::Link.new(TRACK_URI).to_obj.name
    @playlist.at(-1).name.should == @playlist.at(0).name
    @playlist.at(@playlist.length).should equal nil
  end
  
  it "can remove tracks" do
    @playlist.clear!.length.should equal 0
  end
end

describe Hallon::Link do
  it "can parse Spotify URIs" do
    Hallon::Link.new(TRACK_URI).type.should equal :track
  end
  
  it "can render into Spotify URIs" do
    Hallon::Link.new(TRACK_URI).to_str.should == TRACK_URI
  end
  
  it "can be compared with other Spotify URIs" do
    @link = Hallon::Link.new(TRACK_URI)
    TRACK_URI.should == @link
    @link.should == Hallon::Link.new(TRACK_URI)
  end
  
  it "should have the the same ID as the Spotify URL" do
    Hallon::Link.new(TRACK_URI).id.should == '4yJmwG2C1SDgcBbV50xI91'
  end
end

describe Hallon::Track do
  before :all do
    @track = Hallon::Link.new(TRACK_URI).to_obj
  end
  
  it "can be spawned from a link" do
    @track.class.should equal Hallon::Track
  end
  
  it "should have a name" do
    @track.name.should == "The Boys Are Back In Town"
  end
end