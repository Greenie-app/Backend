json.partial! 'pass', locals: {pass: @pass}
json.call @pass, :destroyed?
