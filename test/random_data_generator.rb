module RandomDataGenerator
  private

  def random_data(element_count, key_length)
    data = []
    letters = ('a' .. 'z').to_a

    while data.size < element_count
      key = letters.sample(key_length).join
      content = letters.sample(1)
      data << { key: key, content: content }
    end

    data
  end
end
