
class SCAutoComplete

  def initialize (string, check) 

      if !File.exist?(File.expand_path('~/.sctags'))
          exit
      elsif !string.include?("(") 
          exit
      end

      @result = ""
      extract_class_and_method_names string
      it_was_called_on_a_class = /[[:upper:]]/.match(@sc_class_name[0..0])

      if it_was_called_on_a_class && (check == "0")
          puts "$NAI"
          exit
      end

      if it_was_called_on_a_class
          get_class_file_as_string
          find_method 
      elsif   
          choose_class_for_method 
          puts @result
      end
  end

  def extract_class_and_method_names (string)
      # last_char = string[-1..-1]
      string = string.slice(0..(string.rindex('('))) || string
      array = string.split(/\W+/)
      if /[[:upper:]]/.match(array[-1][0..0])
          @sc_method_name = "new"
          @sc_class_name = array[-1]
      else
          @sc_class_name = array[-2]
          @sc_method_name = array[-1]
      end
  end

  def get_class_file_as_string
      #parse the .sctags file for the class  
      File.open(File.expand_path('~/.sctags'), 'r') do |f|
          f.each_line do |line|
              if (@sc_class_name + "\t") == line[0..@sc_class_name.size]
                  @path = line.split("\t")[1]
              end
          end
      end

      if !@path.nil?
          @sc_file_as_string = File.open(@path) { |f| f.read }
      else
          exit
      end

  end

  def find_method
    check_for_class_name_in_file
    if get_method_args_from_file
      puts @result.gsub(/\s+/, "").gsub("=", ":")
    else
      if get_superclass_from_file
          get_class_file_as_string
          find_method
      end
    end
  end

  def check_for_class_name_in_file
    #TODO There must be a more elegant way for all that!!
    ready = false
    @current_index = @sc_file_as_string.index(@sc_class_name)
    until ready do
        # if there is a semicolon it is a superclass. IF there is a dot it is 
        # used in the code to call a method
        if  @sc_file_as_string[@current_index - 1..@current_index - 1] != ":" &&
            @sc_file_as_string[@current_index - 2..@current_index - 2] != ":" &&
            @sc_file_as_string[@current_index - 1..@current_index - 1] != "." &&
            @sc_file_as_string[@current_index + 1..@current_index + 1] != "." 
        then
            ready = true 
        else
            #scan for the name of the class again
            @current_index = @sc_file_as_string.index(@sc_class_name, @current_index + 1)
        end 
    end
  end

  def get_method_args_from_file
    ready = false
    @current_index = @sc_file_as_string.index("{", @current_index + 1)
    @current_index = @sc_file_as_string.index(@sc_method_name, @current_index + 1)
    if @current_index.nil?
        return false
    end
    #get the index for the end of the word we found
    end_of_method_name_index = @current_index + (@sc_method_name.size - 1);

    #and find the method declaration
    #TODO There must be a more elegant way for all that!!
    until ready do
        if  ( # if there is no dots behind it or in front
            @sc_file_as_string[@current_index - 1..@current_index - 1] != "."  &&
            @sc_file_as_string[end_of_method_name_index + 1..end_of_method_name_index + 1] != "."
            ) &&
            ( #and is preceded by whitespace or an asterisk
            !(@sc_file_as_string[@current_index - 1..@current_index - 1] =~ /\s/).nil?  || 
            @sc_file_as_string[@current_index - 1..@current_index - 1] == "*"
            ) &&
            ( #and it is folowed by opening curly bracket
            @sc_file_as_string[end_of_method_name_index + 1..end_of_method_name_index + 1] == "{" ||
            @sc_file_as_string[end_of_method_name_index + 1..end_of_method_name_index + 2] == " {" ||
            @sc_file_as_string[end_of_method_name_index + 1..end_of_method_name_index + 3] == "  {" ||
            @sc_file_as_string[end_of_method_name_index + 1..end_of_method_name_index + 4] == "   {" 
            )
        then
            ready = true 
        else
            #scan for the name of the method again
            @current_index = @sc_file_as_string.index(@sc_method_name, @current_index + 1)
            #if we can not find the method name
            if @current_index.nil? 
                return false
            end
            #get the index of the last letter of the method name we found
            end_of_method_name_index = @current_index + (@sc_method_name.size - 1);
        end 
    end

    @current_index = @sc_file_as_string.index("{", @current_index + 1)

    #get the index of the next opening bracket (Because if there is no arguments there may be no semicolon and the next search would go over, even to the next class)!
    end_clip_Index = @sc_file_as_string.index("{", @current_index + 1)

    #get the string between the two curly brackets
    extracted_argument_string = @sc_file_as_string[@current_index+1..end_clip_Index-1]

    #distinguish between the two styles: 1) arg keyword 2) pipe characters ||
    if extracted_argument_string.include? "|"
        @current_index = @sc_file_as_string.index("|", @current_index + 1)
        end_clip_Index = @sc_file_as_string.index("|", @current_index + 1)
        @result = @sc_file_as_string[@current_index + 1..end_clip_Index - 1]
        @result =  "$NAI" + @result
        return true
    elsif extracted_argument_string.include? "arg"
        @current_index = @sc_file_as_string.index("arg", @current_index + 1)
        end_clip_Index = @sc_file_as_string.index(";", @current_index + 1)
        @result = @sc_file_as_string[@current_index + 3..end_clip_Index - 1]
        @result =  "$NAI" + @result
        return true
    end
  end
  
  def choose_class_for_method
      method_list = ""
      #parse the .sctags file for the method name
      File.open(File.expand_path('~/.sctags'), 'r') do |f|
          f.each_line do |line|
              if (@sc_method_name + "\t") == line[0..@sc_method_name.size]
                  ln = line.split("\t")
                  class_file = ln[1].split("/")
                  method_list << (ln[0] + " --> " + class_file[-1] + ",")
              end
          end
      end
      unless method_list.empty?
          @result = "$OXI" + method_list
      else
          @result = "$NOP"
      end
  end

  def get_superclass_from_file
    ready = false
    @current_index = @sc_file_as_string.index(@sc_class_name)
    until ready do
        if @current_index.nil?
            return false
        end
        # if there is a semicolon it is a superclass. IF there is a dot it is 
        # used in the code to call a method
        if  @sc_file_as_string[@current_index - 1..@current_index - 1] != ":" &&
            @sc_file_as_string[@current_index - 2..@current_index - 2] != ":" &&
            @sc_file_as_string[@current_index - 1..@current_index - 1] != "." &&
            @sc_file_as_string[@current_index + 1..@current_index + 1] != "." 
        then
            #TODOthis is not bulletproof as it could be that withing 50 characters there is a colon for another reason
            @current_index = @sc_file_as_string[@current_index..@current_index+60].index(":")
            if @current_index.nil?
                return false
            else
                #split from the first colon (for 30 chars) to get the superclass name
                @sc_class_name = @sc_file_as_string[@current_index..@current_index + 60].split(/\W+/, @current_index)[1]
                ready = true 
                return true
            end
        else
            #scan for the name of the class again
            @current_index = @sc_file_as_string.index(@sc_class_name, @current_index + 1)
        end 
    end
    
  end

end

#RUN
arg = ARGV[0]
arg1 = ARGV[1] #if it is just a check this will be 0 else 1.
SCAutoComplete.new(arg, arg1)
