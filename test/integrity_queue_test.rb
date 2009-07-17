require "test/unit"

require "rack"
require "integrity"
require "integrity/notifier/test/fixtures"
require "integrity/queue"
require "bobette/github"
require "bob/test"

require "ruby-debug"

class IntegrityQueueTest < Test::Unit::TestCase
  def setup
    Bob.directory = File.dirname(__FILE__) + "/../tmp"
    Bob.logger    = Logger.new(File.dirname(__FILE__) + "/../bob.log")

    FileUtils.mkdir(Bob.directory)

    DataMapper.setup(:default, "sqlite3:#{File.dirname(__FILE__)}/../tmp/test.db")
    DataMapper.auto_migrate!
  end

  def teardown
    FileUtils.rm_rf(Bob.directory)
  end

  def app
    Bobette.new(Integrity::Queue::Buildable)
  end

  def test_queue
    repo = Bob::Test::GitRepo.new(:holyhub)
    repo.create
    repo.add_successful_commit
    repo.add_failing_commit

    project   = Integrity::Project.gen(:uri => repo.path,
      :branch => "master", :command => "./test")

    payload   = { "scm"     => "git",
                  "uri"     => repo.path,
                  "branch"  => "master",
                  "commits" => repo.commits.map {|c|{"id" => c[:identifier]}}}

    assert Rack::MockRequest.new(app).
      post("/", "bobette.payload" => payload, :lint => true).ok?

    assert_equal 3, project.commits.count
    project.commits.each { |c| assert_equal :pending, c.status }

    2.times { Integrity::Queue::Builder.build }

    project.reload

    assert_equal 3, project.commits.count
    assert_equal 3, Integrity::Commit.count
    assert_equal 2, Integrity::Build.count
    assert_equal :failed,  project.commits[0].status
    assert_equal :success, project.commits[1].status
    assert_equal :pending, project.commits[2].status

    project.commits.each { |commit|
      next if commit.pending?

      assert commit.author.to_s !~ /not loaded/
      assert commit.message !~ /not loaded/
    }
  end
end
