module Methods

  def loadYAMLFile(path)
    YAML::load(File.open(path))
  end

  ###########################################################################################
  # Author: Tim
  # reading CSV data into hash object for each row and return all data in array
  ###########################################################################################
  def loadCSVFile(filePath)
    data = []
    CSV.foreach(filePath, :headers => true) do |row|
      row = row.to_h
      row.each do |k, v|
        v = v.to_s
        row[k] = v
      end
      data << row
    end
    data
  end


  ###########################################################################################
  # Author: Tim
  # convert step description to method name
  ###########################################################################################
  def getMethodName(description)
    description[0] = description[0].downcase
    description.to_s.gsub(' ', '')
  end


  ###########################################################################################
  # Author: Tim
  # Generated Report Out Folder
  ###########################################################################################
  def generatedReportFolder
    currentData, currentTime = DateTime.now.strftime("%Y_%m_%d %H_%M").split(' ')
    path = "#{$ROOT}/../output"
    creatFolder(path)
    path += "/#{currentData}"
    creatFolder(path)
    path += "/#{currentTime}"
    creatFolder(path)
    path
  end

  ###########################################################################################
  # Author: Tim
  # Create folder if folder not exist
  ###########################################################################################
  def creatFolder(path)
    Dir.mkdir(path) unless File.exists?(path)
  end

end