
require 'rubygems'
require 'radiator'
require 'time'


#-----------------------------------
def vote( author, voter, voter_wif , permlink )  

	puts "#{voter} voting for #{author}"

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
		puts "\n Failed to vote for #{author}"
		puts ex.to_s
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
def process_votequeue

	printf "#{@vote_queue.count} "
	if @vote_queue.length > 0

		votable = @vote_queue[0]
		comment = api.get_content(votable[:author], votable[:permlink]).result

		post_epoch = Time.parse( comment.created ).to_i 
		now_epoch  = Time.now.to_i 

		# 30 minutes rule
		if now_epoch - post_epoch > 1500 && now_epoch - post_epoch < 2400
			@voters.each { |v|
				vote( votable[:author], v["user"], v["wif"], votable[:permlink] )
				sleep 1
			}
			@vote_queue.shift!
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
		  			
				if op.parent_author == "" && @popular_fellows.index(op.author) != nil
					votable = {}
					votable[:author] 	= op.author 
					votable[:permlink] 	= op.permlink
					vote_queue << votable
				end


				process_votequeue

			end
		rescue Exception => ex
			puts "Error in stream.operation. Error: #{ ex.to_s }. Retrying.."
			puts ex.backtrace
			sleep 5
		end
	end
end


main


















