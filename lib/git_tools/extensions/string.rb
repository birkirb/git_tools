class String
  def multi_gsub!(options = {})
    options.each do |key, value|
      self.gsub!("{#{key}}", value.to_s)
    end
    self
  end
end
