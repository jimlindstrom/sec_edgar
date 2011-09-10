def recursive_mkdir(dir)
 
  done = false
  parent_directories = []
 
  while !done
    if File.exists? dir
      parent_directories.each do |parent_directory|
        Dir::mkdir parent_directory
      end
      done = true
    else
      parent_directories.unshift dir
      parts = File::split dir
      dir = parts[0]
    end
  end

end
