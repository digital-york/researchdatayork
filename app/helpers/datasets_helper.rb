module DatasetsHelper
  def aips(dataset)
    d = Dlibhydra::Dataset.find(dataset)
    if d.aips.nil?
      return ''
    else
      values = []
      d.aips.each do |a|
        values << "#{a.id} #{a.aip_status}"
      end
      return values
    end
  rescue
    return []
  end

  def dips(dataset)
    d = Dlibhydra::Dataset.find(dataset)
    if d.dips.nil?
      return ''
    else
      values = []
      d.dips.each do |a|
        values << a
      end
      return values
    end
  rescue
    return []
  end

  def get_aip(dataset)
    d = Dlibhydra::Dataset.find(dataset).aips.first
    d
  rescue
    return ''
  end

  def get_dip(dataset)
    d = Dlibhydra::Dataset.find(dataset).dips.first
    d
  rescue
    return ''
  end
end
