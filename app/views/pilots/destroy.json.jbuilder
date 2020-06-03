json.partial! 'pilot', locals: {pilot: @pilot}
json.call @pilot, :destroyed?
