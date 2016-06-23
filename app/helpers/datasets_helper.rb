module DatasetsHelper

  def aips(dataset)
    begin
      d = Dlibhydra::Dataset.find(dataset)
      if d.aip.nil?
        return ''
      else
        values = []
        d.aip.each do | a |
          values << "#{a.id}: #{a.status}"
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
      if d.dip.nil?
        return ''
      else
        values = []
        d.dip.each do | a |
          values << a.id
        end
        return values
      end
    rescue
      return ''
    end
  end
end
