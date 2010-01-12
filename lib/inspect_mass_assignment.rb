
module InspectMassAssignment
  EXCLUDED_METHODS=%w(== === []=)

  def self.inspect_activerecord
    model_classes = get_subclasses(ActiveRecord::Base)
    
    result="<html><body><h1>Attributes and setter methods exposed via mass-assignment</h1>"
    
    if ActiveSupport::Dependencies.mechanism == :load
      result << '<h2 style="color:red">Important: Please set config.cache_classes=true to get reasonable results</h2>'
    end
    
    classes=model_classes.sort {|a,b| a.name <=> b.name}

    result << classes.collect {|r| "<a style=\"color:#{model_status(r)[0]}\" href=\"##{r.name}\">#{r.name}</a>" }.join(' ')
    
    i=-1
    for m in classes
      next if m.respond_to?(:is_abstract_class?) && m.is_abstract_class?
      Rails.logger.info "Inspecting class: #{m}"
      
      result << '<div style="clear:both;"></div>' if i % 3 == 2
      i+=1
      result << "<div style=\"float:left; padding:10px; margin:10px 10px 0 0;width:350px;\"><a name=\"#{m}\"><b>#{m}</b></a>"
      
      record = m.send(:new) rescue nil
      if record.nil?
        result << "Could not instantiate class: #{m}</div>"
        next
      end
      
      st = model_status(m)
      result << "<span style=\"color:#{st[0]};\">#{st[1]}</span>"
      
      setters = record.methods.reject {|wm| EXCLUDED_METHODS.include?(wm)}.select {|wm| wm =~ /=$/}.sort    # explicite methods
      setters.concat m.columns.collect {|c| c.name }            # database attributes

      # generate a hash which contains a value for all setter methods
      h = {}
      setters.each {|s| h[s.gsub(/=$/, '')]='some random value'}

      safe_h = record.send(:remove_attributes_protected_from_mass_assignment, h)

      result << "<table width=\"100%\"><th>name</td><th>type</th><th><a target=\"_blank\" href=\"http://apidock.com/ruby/Method/arity\">arity</a>"
      safe_h.keys.sort.each do |k|
        result << inspect_method(record, k)
      end
      result << '</table></div>'
    end
    
    result << "</body>"
    result
  end
  
  def self.model_status(m)
    if !m.accessible_attributes.nil?
      [:green, 'attr_accessible']
    elsif !m.protected_attributes.nil? && m.protected_attributes.size > 0
      [:yellow, 'attr_protected']
    else
      [:red, 'unprotected']
    end
  end
  
  def self.inspect_method(record, method)
    result = ""
    result << "<tr><td>#{method}=</td>"
    
    type = method_type(record, method)
    result << "<td>#{type}</td>"
    
    arity = type=='attribute' ? 1 : record.method("#{method}=").arity   # db attributes setters have arity of 1
    result << "<td style=\"color:#{arity < 2 ? 'red':'green'};\">#{arity}</td></tr>"
    result
  end

  def self.method_type(record, method)
    return "association" if record.class.reflections.keys.include?(method.to_sym)
    return "association" if record.class.reflections.keys.include?(method.gsub(/_ids$/, 's').to_sym)    # also recognized the "_ids" association setter method as association
    return "attribute" if record.class.columns.collect{|c| c.name}.include?(method)
    return "method"
  end

  def self.get_subclasses(klass) 
   a = ObjectSpace.enum_for(:each_object, class << klass; self; end).to_a.uniq
   a.reject! {|c| c == ActiveRecord::Base}
   a
  end    
    
end
