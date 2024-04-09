# frozen_string_literal: true

require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  if phone_number.size < 10
    phone_number = "It's a bad number"
  else
    phone_number[0] = '' if phone_number.size > 10 && phone_number[0] == '1'
    phone_number.gsub(/[-.() ]/, '')
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
count_by_days = {}
count_by_hours = {}

contents.each do |row| # Thanks letter generator
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  puts phone_number = clean_phone_number(row[:homephone])

  date_format = Time.strptime(row[:regdate], '%m/%d/%y %H:%M')

  if count_by_days[date_format.wday] == nil
    count_by_days[date_format.wday] = 1
  else
    count_by_hours[date_format.wday] = 1
  end

  if count_by_hours[date_format.hour] == nil
    count_by_hours[date_format.hour] = 1
  else
    count_by_hours[date_format.hour] += 1
  end

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts count_by_days
puts count_by_hours
