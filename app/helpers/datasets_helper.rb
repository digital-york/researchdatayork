module DatasetsHelper

  def aips(dataset)
    d = Dlibhydra::Dataset.find(dataset)
    if d.aip.nil?
      return ''
    else
      values = []
      d.aip.each do | a |
        values << "#{a.id}: #{a.data_status}"
      end
      return values
    end
  end
end
