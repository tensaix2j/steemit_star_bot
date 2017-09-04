
require 'rubygems'
require 'radiator'
require 'time'


#-----------------------------------
def vote( author, voter, voter_wif , permlink )  

	puts "#{voter} to vote for #{author}"

	begin
		tx = Radiator::Transaction.new(wif: voter_wif)
		vote = {
		  type: :vote,
		  voter: voter,
		  author: author,
		  permlink: permlink,
		  weight: 10000
		}

		tx.operations << vote
		tx.process(true)

	rescue Exception => ex
		puts "\n Failed to vote for #{author}. Error #{ex.to_s}"
	end	
end



#-----------------------
def populate_voters
	
	@voters = []
	@popular_fellows = []

	begin
		config = JSON.parse( open("config.json").read() )
		@voters 			= config["voters"]
		@popular_fellows 	= config["popular_fellows"]

	rescue Exception => ex
		puts ex.to_s
	end

end



#-------------------------
def process_votequeue( api )

	if @vote_queue.length > 0

		votable = @vote_queue[0]
		
		if Time.now.to_i >= votable[:votetime]
			@voters.each { |v|
				vote( votable[:author], v["user"], v["wif"], votable[:permlink] )
				sleep 3
			}
			@vote_queue.shift
		end	
	end				
end




#---------------------
@vote_queue = []
def main
		
	populate_voters

	p @voters 
	p @popular_fellows

	loop do
		
		stream 	= Radiator::Stream.new
		api  	= Radiator::Api.new
		
		begin 
			
			stream.operations(:comment) do |op|
		  		
		  		if op["parent_author"] == "" && @popular_fellows.index(op["author"]) != nil 
					
					votable = {}
					votable[:author] 	= op["author"] 
					votable[:permlink] 	= op["permlink"]

					#after 14 minutes 30 seconds must vote already..
					votable[:votetime]	= Time.now.to_i + 14 * 60 + 30
					@vote_queue << votable

					puts "#{ Time.now().strftime("%Y%m%d.%H%M%S") } (#{ Time.now.to_i }) : Queued : #{ votable.inspect }"
				end


				process_votequeue(api)

			end
		rescue Exception => ex
			puts "Error in stream.operation. Error: #{ ex.to_s }. Retrying.."
			sleep 5
		end
	end
end


main


















