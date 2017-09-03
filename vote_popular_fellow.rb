
require 'rubygems'
require 'radiator'


#-----------------------------------
def vote( author, voter, voter_wif , permlink )  

	puts "#{voter} voting for #{author}"
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

end

#---------------------
def main
		
	populate_voters

	p @voters 
	p @popular_fellows

	stream = Radiator::Stream.new
	stream.operations(:comment) do |op|
  
		if op.parent_author == "" && @popular_fellows.index(op.author) != nil
			@voters.each { |v|
				vote( op.author, v["user"], v["wif"], op.permlink )
			}
		end
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

main


















