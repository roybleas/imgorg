require 'exifr'
require 'singleton'

class ImageId
	#store the image name and links to other images in the list 
	attr_accessor :previous_index, :next_index, :width, :height, :orientation 
	attr_reader :imagefile
	
	def initialize(fileimage,previous_index = -1, next_index = -1)
		@orientation = :portrait
		@imagefile = fileimage
		@previous_index = previous_index
		@next_index = next_index
	end
end

class Imagelist
	# list is an array of class ImageId 
	# folder is the location of the images
	attr_accessor :list, :folder, :filename_prefix, :initial_sequence_number
	attr_reader :created
	
	def initialize(list,  folder="", filename_prefix="")
		@created = Time.now
		@initial_sequence_number = 1
		@default_width = 600
		@default_height = 800
		@list = []
		loadimages(list)
		@storelist = list
		@folder = folder
		@filename_prefix = filename_prefix
		if filename_prefix == ""
			@filename_prefix = self.filename_common_prefix
		end
		@initial_sequence_number = first_sequence_number
		load_image_dimensions
	end
	
	# extract the image file from the array
	def filename(idx)
		idx = valid_index(idx)
		@list[idx].imagefile
	end
		
	#create an array of the indexes of the imagedIds in ascending order
	def image_index_list_asc()
			
		# find the index of the first image id
		this_idx = self.first_index
		
		index_list = Array.new(@list.size)
		index_list.each_index do |i|
			# set the current extracted index into the array
			index_list[i] = this_idx
			# look up the next linked index and set it as current
			this_idx = @list[this_idx].next_index
		end
		return index_list
	end
	
	#same as image_index_list_asc only in descending order 
	def image_index_list_desc()
		#start with the last imageId in the list time
		this_idx = self.last_index
		
		index_list = Array.new(@list.size)
		index_list.each_index do |i|
			# set the current extracted index into the array
			index_list[i] = this_idx
			# look up the previous linked index and set it as current
			this_idx = @list[this_idx].previous_index
		end
		return index_list
	end
	
	# look up the index of the previous image in the list
	def previous(idx)
		# verify the passed index and set to a valid value
		idx = valid_index(idx)
		
		new_index = @list[idx].previous_index
		if new_index == -1 then
			# if it is the first index loop back to the end
			new_index = self.last_index
		end
		return new_index
	end
	
	# look up the index of the next image in the list
	def next(idx)
		# verify the passed index and set to a valid value
		idx = valid_index(idx)
		
		new_index = @list[idx].next_index
		if new_index == -1 then
			# if it is the last index loop back to the beginning
			new_index = self.first_index
		end
		return new_index
	end
	
	# located the index of the last imageId in the list
	def last_index
		# set default value
		last_idx = @list.size - 1
		
		# loop through list till next = -1 and then save and exit loop
		@list.each_index do |idx|
			if @list[idx].next_index == -1 then
				last_idx = idx
				break
			end
		end
		
		return last_idx
	end
	
	# located the index of the first imageId in the list
	def first_index
		# set default value
		first_idx = 0
		
		# loop through list till previous = -1 and then save and exit loop
		@list.each_index do |idx|
			if @list[idx].previous_index == -1 then
				first_idx = idx
				break
			end
		end
		return first_idx
	end
	
	# move the imageId of the passed index one higher up the link list
	def move_next(idx)
		if valid_index(idx) == idx then
			#verify not already at the end 
			if @list[idx].next_index != -1 then
				this_imageId = @list[idx]
				next_imageId = @list[this_imageId.next_index]
				
				swap_image_indexes(this_imageId,next_imageId)
			else
				#make last item the first in the sequence
				
				#save current last and first indexes
				curr_first_index = self.first_index
				curr_last_index = idx
				
				
				curr_first_image = @list[curr_first_index]
				curr_last_image = @list[curr_last_index]
				
				#point current first image to follow current last image
				curr_first_image.previous_index = curr_last_index
				
				#make the image before the current last image the last in the sequence
				@list[curr_last_image.previous_index].next_index = -1
				
				#point the current last image to be before the current first image 
				curr_last_image.next_index = curr_first_index
				
				#finally change current last to be first in the sequence
				curr_last_image.previous_index = -1
			end
		end
	end		
	
	# move the imageId of the passed index one lower in the link list
	def move_previous(idx)
		if valid_index(idx) == idx then
			#verify not already at the beginning 
			if @list[idx].previous_index != -1 then
				this_imageId = @list[idx]
				previous_imageId = @list[this_imageId.previous_index]
				
				swap_image_indexes(previous_imageId ,this_imageId)
			else
				#make first item the last in the sequence
				
				#save current last and first indexes
				curr_last_index = self.last_index
				curr_first_index = idx
				
				curr_first_image = @list[curr_first_index]
				curr_last_image = @list[curr_last_index]
				
				#point current last to be before current first_index
				curr_last_image.next_index = curr_first_index
				
				#make the image following the first image the first in the sequence
				@list[curr_first_image.next_index].previous_index = -1
				
				#point the current first to follow the current last image 
				curr_first_image.previous_index = curr_last_index
				
				#finally change current first to be last in the sequence
				curr_first_image.next_index = -1
			end
		end
	end		
	
	def fullpath(idx)
		# if no folder set just return filename
		if @folder == ""
			self.filename(idx)
		else
			File.join(@folder,self.filename(idx))
		end
	end
	
	# see if the sequence has been updated
	def changed?
		Array(0...@list.size) != self.image_index_list_asc
	end
	
	# review files to see if sequence numbers already included
	def has_sequence_numbers?
		sequence_filenames.size > 0
	end
	
	
	#get image file width
	def image_width(idx)
		# verify the passed index and set to a valid value
		idx = valid_index(idx)
		#verify the folder location has been set
		if @folder != ""
			@list[idx].width
		else
			@default_width
		end
	end
	
  #get image file height
	def image_height(idx)
		# verify the passed index and set to a valid value
		idx = valid_index(idx)
		#verify the folder location has been set
		if @folder != ""
			@list[idx].height
		else
			@default_height
		end
	end
	
	def image_orientation(idx)
		
		# verify the passed index and set to a valid value
		idx = valid_index(idx)
		if @list[idx].orientation == :landscape
			return "Landscape"
		else
			return "Portrait"
		end
	end
	
	#get file name prefix if exists
	def filename_common_prefix
		filelist = sequence_filenames
		if filelist.size == 1 
			# success files all have same prefix
			common_prefix = filelist[0]
		else
			common_prefix = ""
		end
	
		return common_prefix
	end
	
	# rename filenames to match sequence applying a sequence number suffix
	# format like filename_000.jpg
	def save
		# verify we have a valid folder location
		raise ArgumentError, "Invalid folder: #{@folder}" unless FileTest.directory?(@folder)
		
		# verify a filenameprefix exists
		raise ArgumentError, "Missing file prefix " if @filename_prefix.empty?
		
		#get the new sorted file list
		seq_list = self.image_index_list_asc
		cnt = @initial_sequence_number - 1
		tmpsuffix = ".temp"
		seq_list.map do |idx|
			# create a new sequenced file name
			cnt += 1
			newfilename =  sprintf("%s_%03d.jpg",@filename_prefix, cnt)
			
			#if the name matches existing file ignore
			if newfilename != self.filename(idx)
			
				# rename to new name with temporary suffix so not overwrite an existing file 
				newfilename = File.join(@folder,newfilename + tmpsuffix)
				File.rename(self.fullpath(idx),newfilename)
			end
		end
		
		# collect files with the temporary file suffix
		file_list = Dir.glob(File.join(@folder,"*" + tmpsuffix))
		
		# and rename to correct name
		file_list.each do |f|
  		n = f.sub(/#{tmpsuffix}$/, '')
  		File.rename(f , n)
		end
	end
	
	
	private 
	
	# get list of file names with sequence numbers
	def sequence_filenames
		searchfor = /_\d{3}[.]jpe?g$/
		filelist = @list.map { |img| img.imagefile}.select{|img| img[searchfor]}
		filelist.map{ |img| img.gsub(searchfor,"") }.uniq
	end
	
	#create an array of linked imageIds
	def loadimages(list)
		# as long as the list has some values
		if list.size > 0 
			idx_prev = -1
			idx_next = 1
			list.each do |filename|
				@list << ImageId.new( filename,idx_prev,idx_next)
				idx_prev += 1
				idx_next += 1
			end
			
			@list[-1].next_index = -1
		end
	end
	
	# validate the passed index is within the size of the array list
	# and set ot 0 if less than zero or last array if grater than array size 
	def valid_index(idx)
		idx = 0 if idx < 0 
		idx = @list.size -1 if idx >= @list.size
		return idx
	end
	
	# swap the positions of the first ImageId with the second passed ImageId 
	def swap_image_indexes(this_imageId,next_imageId)
		#keep a copy of this image to update next image
		save_currImageId = this_imageId.clone
		save_otherImageId = next_imageId.clone
		
		#redirect the items around the items we are going to swap
		# first confirm it is not the first in the list
		if this_imageId.previous_index != -1
			@list[this_imageId.previous_index].next_index = this_imageId.next_index
		end
		#and confirm not last in the list
		if next_imageId.next_index != -1
			@list[next_imageId.next_index].previous_index = next_imageId.previous_index
		end
		
		#move previous to next and swap current previous to this one
		next_imageId.next_index = next_imageId.previous_index
		next_imageId.previous_index = save_currImageId.previous_index
		
		#move next to previous and swap next next to this one
		this_imageId.previous_index = this_imageId.next_index
		this_imageId.next_index = save_otherImageId.next_index	
	end
	
	def get_filename_prefix
		searchfor = '*_[0-9].*'
 
  	location = File.join(File.dirname(__FILE__), 'imgorg_myfiles','gallery')
  
  	file_list = Dir.glob(File.join(location,searchfor))
		
	
	end
	
	# see if there is an existing sequence number and find first
	def first_sequence_number
		filelist = sequence_filenames
		if filelist.size == 1 then
			filename_prefix = @filename_prefix + "_"
			this_seq_number = []
			@list.each_index do |idx|
				this_seq_number << self.filename(idx).sub(filename_prefix,"").sub(".jpg","").to_i
			end
			if this_seq_number.size > 0 
				this_seq_number.sort
				save_seq_number = this_seq_number[0] if this_seq_number[0] > 0
			end
		end
		save_seq_number	||= 1
	end
	
	#load image dimensions 
	def load_image_dimensions
		#verify the folder location has been set
		if @folder != ""
			@list.each_index { |idx|
				filename = self.fullpath(idx)
				begin
					#Note: only loads jpg files for now
					
					
					@list[idx].width = EXIFR::JPEG.new(filename).width 
					@list[idx].height = EXIFR::JPEG.new(filename).height
					if @list[idx].width > @list[idx].height
						@list[idx].orientation = :landscape
					end
				rescue Errno::ENOENT 
					#use default values
					@list[idx].width = "?"
					@list[idx].height = "?"
				rescue EXIFR::MalformedJPEG
					#use default values
					@list[idx].width = "?"
					@list[idx].height = "?"
				end
			}
		end
	end				
end

class Last_gallery_load_date
	include Singleton
	attr_accessor :creationtime
	
	def initialize
		@creationtime = Time.now
	end
	
	def updated?(testdate)
		@creationtime > testdate
	end
end
		
		