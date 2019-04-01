class PageObject

  ###########################################################################################
  # Author: Tim
  # Initialize watir page object in selenium webDriver
  # Group objects by Screen
  ###########################################################################################
  def initializePageObject(browser, objConfigs)
    actionObjects = {}
    objConfigs.each do |obj|
      obj = createPageObject(browser, obj)
      screen = obj['Screen']
      if actionObjects[screen] == nil
        actionObjects[screen] = [obj]
      else
        actionObjects[screen] << obj
      end
    end
    actionObjects
  end

  ###########################################################################################
  # Author: Tim
  # Initialize all page object for all screen
  ###########################################################################################
  def createPageObject(browser, obj)
    tag = obj['HTML Tag']
    locatorType = obj['Locator Type']
    locatorVal = obj['Locator Value']
    if tag.to_s != '' && locatorType.to_s != '' && locatorVal.to_s != ''
      obj['pageObj'] = eval("browser.#{tag}(:#{locatorType}=>'#{locatorVal}')")
    else
      obj['pageObj'] = nil
    end
    obj
  end
end