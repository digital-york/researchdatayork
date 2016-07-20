module DatasetsHelper

  def aips(dataset)
    begin
      d = Dlibhydra::Dataset.find(dataset)
      if d.aip.nil?
        return ''
      else
        values = []
        d.aip.each do | a |
          values << "#{a.id}: #{a.aip_status}"
        end
        return values
      end
    rescue
      return ''
    end
  end

  def dips(dataset)
    begin
      d = Dlibhydra::Dataset.find(dataset)
      if d.aip.nil?
        return ''
      else
        values = []
        d.aip.each do | a |
          if a.dip? == true
            values << a.id
          elsif a.first_requestor != nil
            values << a.id
          end
        end
        return values
      end
    rescue
      return ''
    end
  end
end
