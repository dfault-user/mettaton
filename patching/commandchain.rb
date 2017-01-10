module Discordrb::Commands
	class CommandChain
		def execute_bare(event)
			result = ''
			quoted = false
			hacky_delim, hacky_space, hacky_prev = [0xe001, 0xe002, 0xe003].pack('U*').chars
			
			escaped = false

			@chain.each_char.each_with_index do |char, index|
				# Escape character
				if char == '\\' && !escaped
					escaped = true
					next
				elsif escaped
					result += char
					escaped = false
					next
				end
				
				# Quote begin
				if char == @attributes[:quote_start] && !quoted
					quoted = true
					next
				end
				
				# Quote end
				if char == @attributes[:quote_end] && quoted
					quoted = false
					next
				end
				
				if char == ' ' && quoted
					result += hacky_space
					next
				end
				
				result += char
			end

			@chain = result

			@chain_args, @chain = divide_chain(@chain)

			prev = ''

			chain_to_split = @chain

			# Don't break if a command is called the same thing as the chain delimiter
			chain_to_split.slice!(1..-1) if chain_to_split.start_with?(@attributes[:chain_delimiter])

			first = true
			split_chain = chain_to_split.split(@attributes[:chain_delimiter])
			split_chain.each do |command|
				command = @attributes[:chain_delimiter] + command if first && @chain.start_with?(@attributes[:chain_delimiter])
				first = false

				command = command.strip

				# Replace the hacky delimiter that was used inside quotes with actual delimiters
				command = command.gsub hacky_delim, @attributes[:chain_delimiter]

				first_space = command.index ' '
				command_name = first_space ? command[0..first_space - 1] : command
				arguments = first_space ? command[first_space + 1..-1] : ''

				# Append a previous sign if none is present
				arguments += @attributes[:previous] unless arguments.include? @attributes[:previous]
				arguments = arguments.gsub @attributes[:previous], prev

				# Replace hacky previous signs with actual ones
				arguments = arguments.gsub hacky_prev, @attributes[:previous]

				arguments = arguments.split ' '

				# Replace the hacky spaces with actual spaces
				arguments.map! do |elem|
					elem.gsub hacky_space, ' '
				end

				# Finally execute the command
				prev = @bot.execute_command(command_name.to_sym, event, arguments, split_chain.length > 1 || @subchain)
			end

			prev
		end
	end
end