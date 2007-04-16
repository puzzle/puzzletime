
class PBMig

def moveWorktimes(from, to)
   Projecttime.find_all_by_project_id(from).each do |wt|
	wt.update_attribute :project_id, to
   end
end

def clientShortname(id, name)
	Client.find(id).update_attribute :shortname, name
end

def projectShortname(id, name)
	Project.find(id).update_attribute :shortname, name
end


def migrate
	moveWorktimes 18, 35
	moveWorktimes 25, 24
	moveWorktimes 27, 1
	Projecttime.find(433).update_attribute :project_id, 23
	Project.destroy [18, 25, 27]
	
	Client.destroy [6, 9]
	
	clientShortname 8, 'BABS'
	clientShortname 2, 'DLCB'
	clientShortname 3, 'FUBV'
	clientShortname 10, 'ALTD'
	clientShortname 4, 'PITC'
	clientShortname 5, 'SBBI'
	clientShortname 7, 'SDAB'
	clientShortname 1, 'STOP'
	clientShortname 11, 'TRGO'

	projectShortname 23, 'CHR'
	projectShortname 5, 'DLV'
	projectShortname 13, 'SWV'
	projectShortname 14, 'PGW'
	projectShortname 15, 'POC'
	projectShortname 30, 'INF'
	projectShortname 26, 'SUP'
	projectShortname 4, 'ALG'
	projectShortname 19, 'ASB'
	projectShortname 20, 'FIN'
	projectShortname 34, 'FOP'
	projectShortname 24, 'INF'
	projectShortname 6, 'RE7'
	projectShortname 31, 'SYE'
	projectShortname 7, 'LWS'
	projectShortname 39, 'MKT'
	projectShortname 32, 'PNG'
	projectShortname 11, 'PZT'
	projectShortname 10, 'SEP'
	projectShortname 35, 'VRK'
	projectShortname 9, 'FGE'
	projectShortname 16, 'SFA'
	projectShortname 38, 'SFE'
	projectShortname 12, 'UNO'
	projectShortname 21, 'DSY'
	projectShortname 4, 'BZL'
	projectShortname 33, 'OMS'
	projectShortname 2, 'WSL'
	projectShortname 1, 'UWA'
	projectShortname 36, 'INF'
	projectShortname 28, 'SUP'
	projectShortname 37, 'SUP'

	Employee.find(:all).each do |e|
		e.update_attribute :shortname, e.shortname.upcase
	end
end

end
