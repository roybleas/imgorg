require "minitest/autorun"
require "timecop"

require_relative("imgorg.rb")

class Testimglist < MiniTest::Unit::TestCase
  def setup
  	@testfilelist = ["FileA","FileB","FileC"]
    @imagelist = Imagelist.new(@testfilelist)
  end

  def test_loadfilelist
    assert_equal @imagelist.list.size, @testfilelist.size
  end

	def test_imagefilenames
		assert_equal @imagelist.filename(0), @testfilelist[0]
		assert_equal @imagelist.filename(1), @testfilelist[1]
		assert_equal @imagelist.filename(2), @testfilelist[2]
	end
	
	def test_link_next
		assert_equal 1, @imagelist.next(0)
		assert_equal 2, @imagelist.next(1)
		assert_equal 0, @imagelist.next(2)
	end
	
	def test_link_previous
		assert_equal 2, @imagelist.previous(0)
		assert_equal 0, @imagelist.previous(1)
		assert_equal 1, @imagelist.previous(2)
	end
	
	def test_end_links
		assert_equal 0,@imagelist.first_index
		assert_equal 2,@imagelist.last_index
	end
	
	def test_image_list_order
		assert_equal @imagelist.image_index_list_asc,[0,1,2]
		assert_equal @imagelist.image_index_list_desc,[2,1,0]
	end
	
end

class Test_creation < MiniTest::Unit::TestCase
	def setup
		
  	@testfilelist = ["FileA","FileB","FileC"]
  	Last_creation_date.instance.creationtime = Time.now
  end
  
	def test_created
		Timecop.freeze(Time.local(2014)) 
			this_imagelist = Imagelist.new(@testfilelist)
			assert_equal this_imagelist.created, Time.now
		Timecop.return
		this_imagelist = Imagelist.new(@testfilelist)
		assert this_imagelist.created < (Time.now + 1 )
	end
	
	def test_list_updated
		this_imagelist = Imagelist.new(@testfilelist)
		saved_list = Last_creation_date.instance
		saved_list.creationtime = this_imagelist.created
		assert_equal saved_list.creationtime, this_imagelist.created
		refute saved_list.updated?(this_imagelist.created)
		Timecop.travel(Time.now + 60)
			new_imagelist = Imagelist.new(@testfilelist)
			saved_list.creationtime = new_imagelist.created
		Timecop.return
		assert saved_list.updated?(this_imagelist.created)
		
		this_save_list = Last_creation_date.instance
		assert this_save_list.updated?(this_imagelist.created)
		refute this_save_list.updated?(new_imagelist.created)
		
	end
		
		
end

class Testimglistmove < MiniTest::Unit::TestCase

	def setup
  	@testfilelist = ["FileA","FileB","FileC","FileD","FileE"]

  end
  
  def test_move_next
  	this_imagelist = Imagelist.new(@testfilelist)
  	
  	this_idx = 2
  	next_idx = this_imagelist.next(this_idx)

  	#before values
  	before_this_idx_previous = this_imagelist.previous(this_idx)
  	before_this_idx_next = this_imagelist.next(this_idx)

  	before_next_idx_previous = this_imagelist.previous(next_idx)
  	before_next_idx_next = this_imagelist.next(next_idx)
  	
  	#after values
  	after_this_idx_previous = next_idx
  	after_this_idx_next = before_next_idx_next
  	
  	after_next_idx_previous = before_this_idx_previous
  	after_next_idx_next = this_idx
  	
  	# test 
  	
  	curridx = this_idx
  	nextidx = next_idx
  	  	
  	assert_equal before_this_idx_previous, this_imagelist.previous(curridx)
  	assert_equal before_this_idx_next, this_imagelist.next(curridx)
  	assert_equal before_next_idx_previous, this_imagelist.previous(nextidx)
  	assert_equal before_next_idx_next, this_imagelist.next(nextidx)
  	  	
  	this_imagelist.move_next(curridx)
  	
  	assert_equal after_this_idx_previous, this_imagelist.previous(curridx)
  	assert_equal after_this_idx_next, this_imagelist.next(curridx)
  	assert_equal after_next_idx_previous, this_imagelist.previous(nextidx)
  	assert_equal after_next_idx_next, this_imagelist.next(nextidx)

  end
  
  def test_move_next_swap_then_swap_back
  	this_imagelist = Imagelist.new(@testfilelist)
  	
  	assert_equal [0,1,2,3,4],this_imagelist.image_index_list_asc
  	this_imagelist.move_next(2)
  	assert_equal [0,1,3,2,4],this_imagelist.image_index_list_asc
  	#move them back
  	this_imagelist.move_next(3)
  	assert_equal [0,1,2,3,4],this_imagelist.image_index_list_asc
  end
  
  def test_move_next_shuffle_first_to_last 
  	this_imagelist = Imagelist.new(@testfilelist)
  	
  	#shuffle first to last 
  	assert_equal [0,1,2,3,4],this_imagelist.image_index_list_asc

  	this_imagelist.move_next(0)
  	assert_equal [1,0,2,3,4],this_imagelist.image_index_list_asc
  	
  	this_imagelist.move_next(0)
  	assert_equal [1,2,0,3,4],this_imagelist.image_index_list_asc
  	
  	this_imagelist.move_next(0)
  	assert_equal [1,2,3,0,4],this_imagelist.image_index_list_asc
  	
  	this_imagelist.move_next(0)
  	assert_equal [1,2,3,4,0],this_imagelist.image_index_list_asc
  	
  	this_imagelist.move_next(0)
  	assert_equal [1,2,3,4,0],this_imagelist.image_index_list_asc
  end
  
  def test_move_previous_swap_then_swap_back
  	this_imagelist = Imagelist.new(@testfilelist)
  	
  	assert_equal [0,1,2,3,4],this_imagelist.image_index_list_asc
  	this_imagelist.move_previous(3)
  	assert_equal [0,1,3,2,4],this_imagelist.image_index_list_asc
  	#move them back
  	this_imagelist.move_previous(2)
  	assert_equal [0,1,2,3,4],this_imagelist.image_index_list_asc
  end
  
  def test_move_previous_shuffle_last_to_first 
  	this_imagelist = Imagelist.new(@testfilelist)
  	
  	#shuffle first to last 
  	assert_equal [0,1,2,3,4],this_imagelist.image_index_list_asc

  	this_imagelist.move_previous(4)
  	assert_equal [0,1,2,4,3],this_imagelist.image_index_list_asc
  	
  	this_imagelist.move_previous(4)
  	assert_equal [0,1,4,2,3],this_imagelist.image_index_list_asc
  	
  	this_imagelist.move_previous(4)
  	assert_equal [0,4,1,2,3],this_imagelist.image_index_list_asc
  	
  	this_imagelist.move_previous(4)
  	assert_equal [4,0,1,2,3],this_imagelist.image_index_list_asc
  	
  	this_imagelist.move_previous(4)
  	assert_equal [4,0,1,2,3],this_imagelist.image_index_list_asc
  end
end

class Testimglistfilenames < MiniTest::Unit::TestCase
	def setup
  	@testfilelist = ["FileA","FileB","FileC","FileD","FileE"]
	end
  
  def test_pathnames
  	this_imagelist = Imagelist.new(@testfilelist)
  	assert_equal "FileA",this_imagelist.filename(0)
  	assert_equal "FileA",this_imagelist.fullpath(0)
		
		somefoldername = 'C:/some/folder/name'
				
  	this_imagelist.folder = somefoldername
  	
  	assert_equal "FileA",this_imagelist.filename(0)
  	assert_equal somefoldername + "/FileA",this_imagelist.fullpath(0)
  end
  
  def test_pathname_initialisation
  	somefoldername = 'C:/some/folder/name'
  	this_imagelist = Imagelist.new(@testfilelist,somefoldername = 'C:/some/folder/name')
  	assert_equal somefoldername, this_imagelist.folder
  end
end

class Testsequence_changed < MiniTest::Unit::TestCase
	def setup
  	@testfilelist1 = ["FileA","FileB","FileC","FileD","FileE"]
	end
	
	def test_changed 
		this_imagelist = Imagelist.new(@testfilelist1)
		refute this_imagelist.changed?
		
		this_imagelist.move_next(0)
		assert this_imagelist.changed?
		
		this_imagelist.move_previous(0)
		refute this_imagelist.changed?
	end
end

class Testsequence < MiniTest::Unit::TestCase
	def setup
		@testfilelist1 = ["FileA","FileB","FileC","FileD","FileE"]
  	@testfilelist2 = ["FileA_001.jpg","FileB_025.jpg","FileC_039.jpg","FileD_040.jpg","FileE_123.jpg"]
  	@testfilelist3 = ["exampleimage_001_001.jpg", "exampleimage_001_002.jpg", "exampleimage_001_003.jpg", "exampleimage_001_004.jpg", "exampleimage_001_005.jpg", "exampleimage_001_006.jpg", "exampleimage_001_007.jpg", "exampleimage_001_008.jpg", "exampleimage_001_009.jpg", "exampleimage_001_010.jpg", "exampleimage_001_011.jpg", "exampleimage_001_012.jpg", "exampleimage_001_013.jpg"]
	end
	
	def test_has_sequence_numbers
		
		this_imagelist = Imagelist.new(@testfilelist1)
		refute this_imagelist.has_sequence_numbers?
		
		this_imagelist = Imagelist.new(@testfilelist2)
		assert this_imagelist.has_sequence_numbers?
		
		this_imagelist = Imagelist.new(@testfilelist3)
		assert this_imagelist.has_sequence_numbers?
	end
	
	def test_has_common_prefix
		this_imagelist = Imagelist.new(@testfilelist1)
		file_prefix = this_imagelist.filename_common_prefix
		assert file_prefix.empty?
		
		this_imagelist = Imagelist.new(@testfilelist2)
		file_prefix = this_imagelist.filename_common_prefix
		assert file_prefix.empty?
		
		this_imagelist = Imagelist.new(@testfilelist3)
		file_prefix = this_imagelist.filename_common_prefix
		assert_equal "exampleimage_001", file_prefix
	end
		
	def test_default_common_prefix
		this_imagelist = Imagelist.new(@testfilelist1)
		assert this_imagelist.filename_prefix.empty?
		
		this_imagelist = Imagelist.new(@testfilelist2)
		assert this_imagelist.filename_prefix.empty?
		
		this_imagelist = Imagelist.new(@testfilelist3)
		assert_equal "exampleimage_001", this_imagelist.filename_prefix
		
		this_imagelist = Imagelist.new(@testfilelist3,"","replace_common_prefix")
		assert_equal "replace_common_prefix", this_imagelist.filename_prefix
	end
	
end

class TestInitialSequenceNumber < MiniTest::Unit::TestCase
	def setup
		@testfilelist1 = ["FileA","FileB","FileC","FileD","FileE"]
  	@testfilelist2 = ["FileD_040.jpg","FileB_025.jpg","FileC_039.jpg","FileE_123.jpg","FileA_001.jpg"]
  	@testfilelist3 = ["exampleimage_001_001.jpg", "exampleimage_001_002.jpg", "exampleimage_001_003.jpg", "exampleimage_001_004.jpg", "exampleimage_001_005.jpg", "exampleimage_001_006.jpg", "exampleimage_001_007.jpg"]
		@testfilelist4 = ["exampleimage_002_014.jpg", "exampleimage_002_022.jpg", "exampleimage_002_033.jpg", "exampleimage_002_044.jpg", "exampleimage_002_055.jpg", "exampleimage_002_066.jpg", "exampleimage_002_077.jpg"]
	end
	
	def test_no_sequence 
		default_sequence_number = 1
		
		this_imagelist = Imagelist.new(@testfilelist1)
		assert_equal default_sequence_number,this_imagelist.initial_sequence_number
		
		this_imagelist = Imagelist.new(@testfilelist2)
		assert_equal default_sequence_number,this_imagelist.initial_sequence_number
		
		this_imagelist = Imagelist.new(@testfilelist3)
		assert_equal  1,this_imagelist.initial_sequence_number

		this_imagelist = Imagelist.new(@testfilelist4)
		assert_equal  14,this_imagelist.initial_sequence_number
		
	end

end 

class TestSave < MiniTest::Unit::TestCase
	def setup
		@testfilelist1 = ["FileA","FileB","FileC","FileD","FileE"]
  	@testfilelist2 = ["FileD_040.jpg","FileB_025.jpg","FileC_039.jpg","FileE_123.jpg","FileA_001.jpg"]
  	@testfilelist3 = ["exampleimage_001_001.jpg", "exampleimage_001_002.jpg", "exampleimage_001_003.jpg", "exampleimage_001_004.jpg", "exampleimage_001_005.jpg", "exampleimage_001_006.jpg", "exampleimage_001_007.jpg"]
		@testfilelist4 = ["exampleimage_002_010.jpg", "exampleimage_002_022.jpg", "exampleimage_002_033.jpg", "exampleimage_002_044.jpg", "exampleimage_002_055.jpg", "exampleimage_002_066.jpg", "exampleimage_002_077.jpg"]
		
		fldr = File.join(File.dirname(__FILE__), 'testfiles')
		
		@test_fldr_2 = File.join(fldr, "test2")
		Dir.mkdir(@test_fldr_2) unless File.directory?(@test_fldr_2)
		
		
		# create a file with its name as its contents
		@testfilelist2.each { |filname| File.open(File.join(@test_fldr_2,filname), 'w') {|f| f.write(filname) }}
			
		@test_fldr_3 = File.join(fldr, "test3")
		Dir.mkdir(@test_fldr_3) unless File.directory?(@test_fldr_3)
	
		# create a file with its name as its contents
		@testfilelist3.each { |filname| File.open(File.join(@test_fldr_3,filname), 'w') {|f| f.write(filname) }}
			
		@test_fldr_4 = File.join(fldr, "test4")
		Dir.mkdir(@test_fldr_4) unless File.directory?(@test_fldr_4)
	
		# create a file with its name as its contents
		@testfilelist4.each { |filname| File.open(File.join(@test_fldr_4,filname), 'w') {|f| f.write(filname) }}
			
	end
	
	def teardown
	 	
	 	Dir.glob(File.join(@test_fldr_2,"*.jpg")) {|f| File.delete(f) }
	 	Dir.delete(@test_fldr_2)
	 	Dir.glob(File.join(@test_fldr_3,"*.jpg")) {|f| File.delete(f) }
	 	Dir.delete(@test_fldr_3)
	 	Dir.glob(File.join(@test_fldr_4,"*.jpg")) {|f| File.delete(f) }
	 	Dir.delete(@test_fldr_4)
	 end
	
	def load_pictures(this_folder)
		#create file list
  	imgsuffix = '*.{JPG}' 
  	file_list = Dir.glob(File.join(this_folder,imgsuffix))
   	file_list.each do |img|
  		img.sub!(/#{this_folder}\//, '')
		end
	end
	
	def test_save_error_messages
		
		# test when no destination folder set 
		this_imagelist = Imagelist.new(@testfilelist1)
		assert_raises(ArgumentError) { this_imagelist.save}
		
		#test for invalid or missing folder
		this_imagelist.folder = "/imaginary/folder"
		assert_raises(ArgumentError) { this_imagelist.save}
		
		#test for filename prefix not set
		this_imagelist = Imagelist.new(@testfilelist1,@test_fldr_2)
		assert_raises(ArgumentError) { this_imagelist.save}
	end
	
	def test_save_non_sequenced_fileName
		assert File.directory?(@test_fldr_2)
		
		filelist = load_pictures(@test_fldr_2).sort
		sorted_testfilelist2 = @testfilelist2.sort 
		
		this_imagelist = Imagelist.new(filelist,@test_fldr_2,"common_prefix")
		fullpathfile_list = this_imagelist.image_index_list_asc.collect {|idx| this_imagelist.fullpath(idx)}

		ids = [0,1,2,3,4]
		ids.each { |idx| 
			f = fullpathfile_list[idx] 
			assert_equal sorted_testfilelist2[idx], File.open(f, 'r') { |file| file.read }
		}
		
		this_imagelist.save
		
		filelist = load_pictures(@test_fldr_2).sort
		this_imagelist = Imagelist.new(filelist,@test_fldr_2)
		
		fullpathfile_list = this_imagelist.image_index_list_asc.collect {|idx| this_imagelist.fullpath(idx)}
		ids = [0,1,2,3,4]
		ids.each { |idx| 
			f = fullpathfile_list[idx] 
			assert_equal sorted_testfilelist2[idx], File.open(f, 'r') { |file| file.read }
		}
		cnt = 0
		filename_list = this_imagelist.image_index_list_asc.collect {|idx| this_imagelist.filename(idx)}
		filename_list.each { |f|
			cnt += 1
			newfilename =  sprintf("%s_%03d.jpg","common_prefix", cnt)
			assert_equal newfilename,f
		}
	end
	
	def test_save_already_sequenced_fileName
		assert File.directory?(@test_fldr_3)
		
		filelist = load_pictures(@test_fldr_3).sort
		sorted_testfilelist3 = @testfilelist3.sort 
		
		this_imagelist = Imagelist.new(filelist,@test_fldr_3)
		assert_equal "exampleimage_001", this_imagelist.filename_prefix
		
		fullpathfile_list = this_imagelist.image_index_list_asc.collect {|idx| this_imagelist.fullpath(idx)}

		ids = [0,1,2,3,4,5,6]
		ids.each { |idx| 
			f = fullpathfile_list[idx] 
			assert_equal sorted_testfilelist3[idx], File.open(f, 'r') { |file| file.read }
		}
		
		this_imagelist.move_next(2)
		this_imagelist.move_next(2)
		this_imagelist.move_previous(6)
		assert_equal [0,1,3,4,2,6,5],this_imagelist.image_index_list_asc
		
		save_ids = this_imagelist.image_index_list_asc
		
		save_ids.each { |idx|
			
			f = this_imagelist.fullpath(idx) 
			assert_equal sorted_testfilelist3[idx], File.open(f, 'r') { |file| file.read }
		}
		
		this_imagelist.save
		
		filelist = load_pictures(@test_fldr_3).sort
			
		this_imagelist = Imagelist.new(filelist,@test_fldr_3)
		assert_equal "exampleimage_001", this_imagelist.filename_prefix
		
		assert_equal [0,1,2,3,4,5,6],this_imagelist.image_index_list_asc
		
		cnt = 0
		save_ids.each { |idx| 
			f = this_imagelist.fullpath(cnt) 
			assert_equal sorted_testfilelist3[idx], File.open(f, 'r') { |file| file.read }
			cnt += 1
		}
	end
	
	def test_save_new_start_sequence
		assert File.directory?(@test_fldr_4)
		
		filelist = load_pictures(@test_fldr_4).sort
		sorted_testfilelist4 = @testfilelist4.sort 
		
		this_imagelist = Imagelist.new(filelist,@test_fldr_4)
		assert_equal "exampleimage_002", this_imagelist.filename_prefix
		
		this_imagelist.move_previous(2)
		this_imagelist.move_previous(2)
		this_imagelist.move_next(5)
		assert_equal [2,0,1,3,4,6,5],this_imagelist.image_index_list_asc
		
		test_seq_no = 30
		this_imagelist.initial_sequence_number = test_seq_no
		
		save_ids = this_imagelist.image_index_list_asc	
		this_imagelist.save
		
		newfilelist = load_pictures(@test_fldr_4).sort
		filename_prefix = this_imagelist.filename_prefix + "_"
		seq = test_seq_no
		newfilelist.each { |f|
			assert_equal seq, f.sub(filename_prefix,"").sub(".jpg","").to_i
			seq += 1
		}
	end
		
end
