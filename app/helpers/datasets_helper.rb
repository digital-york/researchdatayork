module DatasetsHelper

  def aips(dataset)
    begin
      d = Dlibhydra::Dataset.find(dataset)
      if d.aips.nil?
        return ''
      else
        values = []
        d.aips.each do | a |
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
      if d.aips.nil?
        return ''
      else
        values = []
        d.aips.each do | a |
          if a.dip? == true
            values << a.id
          elsif a.requestor_email != nil
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
