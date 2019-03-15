def require_all_relative(path)
  caller_path = caller_locations.first.path
  caller_dir = File.dirname(caller_path)
  Dir[File.join(caller_dir, path, '**', '*.rb')].each(&method(:require))
end