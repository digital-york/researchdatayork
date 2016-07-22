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
      if d.dips.nil?
        return ''
      else
        values = []
        d.dips.each do | a |
          values << a.id
        end
        return values
      end
    rescue
      return ''
    end
  end
end
