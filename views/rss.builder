xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
	xml.channel do
		xml.title SITE_TITLE
		xml.description SITE_DESCRIPTION
		xml.link request.url.chomp request.path_info

		@users.each do |user|
			xml.item do
				xml.title h user.content
				xml.link "#{request.url.chomp request.path_info}/#{user.id}"
				xml.guid "#{request.url.chomp request.path_info}/#{user.id}"
				xml.pubDate Time.parse(user.created_at.to_s).rfc822
				xml.description h user.content
			end
		end
	end
end
