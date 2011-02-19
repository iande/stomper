module HeaderHelpers
  
  def table_to_headers(table)
    table.hashes.inject({}) do |hdr, pairs|
      hdr[pairs['header-name']] = pairs['header-value']
      hdr
    end
  end
  
end

World(HeaderHelpers)