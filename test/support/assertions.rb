# Useful assertions not provided by minitest-spec

def assert_present(arg, msg = nil)
  msg ||= "#{arg.inspect} is empty or not present"

  is_present = arg.respond_to?(:empty?) ? !arg.empty? : !arg

  assert is_present, msg
end