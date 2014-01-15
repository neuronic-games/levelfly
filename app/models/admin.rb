class Admin < ActiveRecord::Base
  
  def self.clean_friends
    pmap = {}
    count = 0
    plist = Participant.find(:all, :conditions => {:target_type => "User", :profile_type => "F"})
    plist.each do |p|
      index = "#{p.target_id},#{p.profile_id}"
      if pmap[index].nil?
        pmap[index] = p.id
      else
        Participant.delete(p.id)
        count += 1
        puts "Deleting Participant id:#{p.id} #{index}"
      end
    end
    puts "#{count} deleted"
    return count
  end
  
end