require 'csv'
require 'yaml'
require 'set'
require 'colorize'
require 'watir'
require 'selenium-webdriver'

require '../lib/methods'
require '../lib/pageObject'

class Driver
  include Methods

  ###########################################################################################
  # Author: Tim
  # Initialize data by load all config file
  ###########################################################################################
  def initialize
    envConfigFile = "#{$ROOT}/../config/envConfig.yml"
    @envConfig = loadYAMLFile(envConfigFile)
    stepsFile = "#{$ROOT}/../config/steps.csv"
    @steps = loadCSVFile(stepsFile)
    pageObjectsFile = "#{$ROOT}/../config/pageObjects.csv"
    @pageObjects = loadCSVFile(pageObjectsFile)
    @reportFolder = generatedReportFolder
    @isProcess = true
    @skipCurrentStep = false
    @report = []
  end


  ###########################################################################################
  # Author: Tim
  # Console log for display current step
  ###########################################################################################
  def displayDescription(step)
    description = step['Description'].strip
    description = description.gsub('Parameter1', step['Parameter1'].to_s)
    description = description.gsub('Parameter2', step['Parameter2'].to_s)
    puts description.colorize(:color => :white, :background => :blue)
  end

  ###########################################################################################
  # Author: Tim
  # Automation Framework Driver Process Follow by Step Config
  # call action function if function exist, else call screenActions function
  # Finally generate overall report
  ###########################################################################################
  def driver

    @steps.each do |step|
      begin
        next if step['Run'].to_s.downcase != 'x'
        displayDescription(step)
        @skipCurrentStep = false
        @step = step
        @action = step['Action'].clone

        methodName = getMethodName(step['Action'])
        begin
          send(methodName, step)
        rescue Exception => e
          screenActions
        end
      rescue Exception => e
        @report << [step['Action'], step['Description'], e.message, 'False']
      end
    end

    generateReport
    system("start excel #{@reportFolder}/report.csv")
  end


  ###########################################################################################
  # Author: Tim
  # Open browser according to configuration
  # change Watir default wait time with the waittime show in configuration
  ###########################################################################################
  def openBrowser(step)
    browserName = @envConfig['Browser']
    browserDriver = "#{$ROOT}/../webDriver/#{browserName}driver.exe"
    case browserName
    when 'chrome'
      Selenium::WebDriver::Chrome.driver_path = browserDriver
      # @browser = Watir::Browser.new(:chrome, :switches => %w[--start-maximized])
      @browser = Watir::Browser.new(:chrome)
    when 'firefox'
      Selenium::WebDriver::Firefox.driver_path = browserDriver
      # @browser = Watir::Browser.new(:firefox, :switches => %w[--start-maximized])
      @browser = Watir::Browser.new(:firefox)
    end
    Watir.default_timeout = @envConfig['DefaultWaitTime'].to_s.to_i
    pageObject = PageObject.new
    @actionObjects = pageObject.initializePageObject(@browser, @pageObjects)
  end

  ###########################################################################################
  # Author: Tim
  # Close Selenium Wedriver
  ###########################################################################################
  def closeBrowser(step)
    @browser.quit
  end

  ###########################################################################################
  # Author: Tim
  # Generate Automation Report
  ###########################################################################################
  def generateReport
    filePath = "#{@reportFolder}/report.csv"
    file = File.open(filePath, 'w')
    file.puts ['Screen', 'Description', 'Automation Message', 'Status'].join(',')
    @report.each do |result|
      file.puts result.join(',')
    end
    file.close
  end

  ###########################################################################################
  # Author: Tim
  # Open URL form Selenium Wbdriver
  ###########################################################################################
  def openURL(step)
    url = @step['Parameter1']
    @browser.goto(url)
  end

  ###########################################################################################
  # Author: Tim
  # perform screen actions for all corresponding page object including wait time
  ###########################################################################################
  def screenActions
    actionobjects = @actionObjects[@action]
    return if actionobjects == nil
    actionobjects.each do |obj|
      if obj['Value'] == "uploadfile:@step['Parameter1']"
        p
      end
      waitTime = obj['Wait'].to_s.to_f
      sleep(waitTime)
      objectAction(obj)
      if @skipCurrentStep == true
        break
      end
    end
  end

  ###########################################################################################
  # Author: Tim
  # perform screen page object action like following
  # clicking, fill-in text
  ###########################################################################################
  def objectAction(obj)
    action = obj['Action']
    value = getValue(obj['Value'])
    case action
    when 'click'
      begin
        obj['pageObj'].click
      rescue
        puts "Check Error ID: 9956789034703459".colorize(:color => :red)
      end
    when 'set'
      begin
        obj['pageObj'].set(value)
      rescue Exception => e
        puts e.message.colorize(:color => :white, :background => :red)
        @report << [obj['Screen'], obj['Description'], e.message, 'False']
        @skipCurrentStep = true
      end
    else
      begin
        send(action, obj)
      rescue
        puts "Check Error ID: 93847593874623".colorize(:color => :white, :background => :red)
      end
    end
  end


  ###########################################################################################
  # Author: Tim
  # save new post url
  ###########################################################################################
  def saveNewPostURL(obj)
    if obj['pageObj'].exist?
      status = 'True'
      msg = 'New Post Success'
      value = @browser.url
    else
      status = 'False'
      msg = 'New Post Fail'
      value = ''
    end
    @report << [obj['Screen'], msg, value, status]
  end


  ###########################################################################################
  # Author: Tim
  # saving new search screen
  ###########################################################################################
  def saveSearchPage(obj)
    fileinfo = "#{@reportFolder}/Search #{@step['Parameter1']}"
    saveScreen(fileinfo)
    msg = 'Saving Search result with html and screenshot'
    value = @reportFolder
    @report << [obj['Screen'], msg, value, 'True']
  end


  ###########################################################################################
  # Author: Tim
  # saving current screenshot
  ###########################################################################################
  def saveScreenShot(filepath)
    @browser.screenshot.save(filepath)
  end


  ###########################################################################################
  # Author: Tim
  # saving current HTML page
  ###########################################################################################
  def saveScreenHTML(filepath)
    File.open(filepath, 'w') do |f|
      f.write @browser.html
    end
  end


  ###########################################################################################
  # Author: Tim
  # eval value if value begin with 'eval:'
  # select image if config text is including 'uploadfile:'
  ###########################################################################################
  def getValue(value)
    if value.start_with?('eval:')
      value = value.gsub('eval:', '')
      value = eval(value)
    elsif value.start_with?('uploadfile:')
      value = value.gsub('uploadfile:', '')
      value = eval(value)
      value = "#{$ROOT}/../images/#{value}"
    end
    value
  end


  ###########################################################################################
  # Author: Tim
  # Select Random button from current screen,
  # check if button navigateto a new screen
  # save screen infomation before and after button
  # check if button working or not
  ###########################################################################################
  def randomMode(step)
    buttons = @browser.buttons.to_a
    randomNum = rand(buttons.size)
    randomBtn = buttons[randomNum]
    randomBtnHTML = randomBtn.html
    fileInfo_before = "#{@reportFolder}/#{@step['Parameter1']}_button-#{randomBtn.__id__}_before"
    saveScreen(fileInfo_before)

    begin
      randomBtn.click
    rescue
      puts "Random Button not working, #{randomBtnHTML}".colorize(:color => :white, :background => :red)
      randomBtnReport(randomBtn, randomBtnHTML, false)
      return
    end
    sleep 1
    fileInfo_before = "#{@reportFolder}/#{@step['Parameter1']}_button-#{randomBtn.__id__}_after"
    saveScreen(fileInfo_before)
    randomBtnReport(randomBtn, randomBtnHTML, true)
  end

  ###########################################################################################
  # Author: Tim
  # Generate report for Button Navigation Test
  ###########################################################################################
  def randomBtnReport(randomBtn, randomBtnHTML, buttonFunction)
    screenName = @step['Parameter1']
    purpose = "#{@step['Parameter1']}  Testing Button with ID #{randomBtn.__id__}"
    if buttonFunction == true
      msg = randomBtnHTML
      status = 'N/A - Please Manually Validate Screen Change'
    else
      msg = 'Button Function Not Working'
      status = 'False'
    end
    @report << [screenName, purpose, msg, status]
  end


  ###########################################################################################
  # Author: Tim
  # Save Current ScreenShot and HTML page
  ###########################################################################################
  def saveScreen(fileInfo)
    screenShotPath = "#{fileInfo}.png"
    screenHTMLPath = "#{fileInfo}.html"
    saveScreenShot(screenShotPath)
    saveScreenHTML(screenHTMLPath)
  end


  # Log-In function not use
  # ###########################################################################################
  # # Author: Tim
  # # log-In Exception handling
  # ###########################################################################################
  # def checkLoginError(obj)
  #   loginErrorinfo = @envConfig['SignInError']
  #   if obj['pageObj'].exist?
  #     errorMsg = loginErrorinfo[obj['pageObj'].text]
  #   end
  #
  #   if errorMsg != nil
  #     @report << [obj['Screen'], 'Sign In Fail', errorMsg, 'False']
  #     puts "Script stop Due to Sign-In Error: #{obj['pageObj'].text}".colorize(:color => :white, :background => :yellow)
  #     puts "Please Manually Sign-In in Browser".colorize(:color => :white, :background => :yellow)
  #     puts "Enter y/Y After Manually Sign-In".colorize(:color => :white, :background => :yellow)
  #     puts "Enter n/N If You Wish To Stop".colorize(:color => :white, :background => :yellow)
  #     loginException(obj)
  #   else
  #     @report << [obj['Screen'], 'Sign In Success', '', 'True']
  #   end
  # end
  #
  #
  # ###########################################################################################
  # # Author: Tim
  # # Sign-In Exception, prompt user manually sign-in then press Y or stop by press N
  # ###########################################################################################
  # def loginException(obj)
  #   print 'Enter Your Selection: '
  #   input = gets.chomp
  #   if input.downcase == 'n'
  #     @isProcess = false
  #     return
  #   elsif input.downcase == 'y'
  #     if obj['pageObj'].exist?
  #       puts "Please Manually Sign-In, then Press Y/y".colorize(:color => :white, :background => :yellow)
  #       loginException(obj)
  #     end
  #   else
  #     puts "Invalid Input, Please Input Only Y or N".colorize(:color => :white, :background => :yellow)
  #     loginException(obj)
  #   end
  # end
end