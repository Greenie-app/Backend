json.call logfile, :id, :state, :progress, :created_at, :destroyed?

json.files logfile.files, partial: 'logfiles/file', as: :file
