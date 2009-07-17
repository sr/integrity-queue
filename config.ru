$LOAD_PATH.unshift(File.dirname(__FILE__) + "/lib")

require "integrity"
require "integrity/queue"
require "bobette/github"

Integrity.config = {
  :export_directory => "./builds",
  :log              => "./integrity.log",
  :base_uri         => ""
}

DataMapper.setup(:default, "sqlite3:integrity.db")
DataMapper.auto_upgrade!(:default)

map "/github/SECRET_TOKEN" do
  run Bobette.new(Integrity::Queue::Buildable)
end

map "/" do
  run Integrity::App
end
