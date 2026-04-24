require 'json'
require 'fileutils'

class Notes < AuthenticatedEndpoint
  NOTES_DIR = File.expand_path('../notes', __dir__)

  def self.serve_api(req, res)
    rel  = req.path.delete_prefix('/api/notes').delete_prefix('/')
    full = safe_path(rel)

    return error(res, 400, 'invalid path') unless full

    case req.request_method
    when 'GET'
      if File.directory?(full)
        res.content_type = 'application/json'
        res.body = list(full).to_json
      elsif File.exist?(full)
        res.content_type = 'text/plain; charset=utf-8'
        res.body = File.read(full)
      else
        error(res, 404, 'not found')
      end
    when 'PUT'
      return error(res, 404, 'not found') unless File.exist?(full)
      File.write(full, req.body)
      json(res, ok: true)
    when 'POST'
      return error(res, 409, 'already exists') if File.exist?(full)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, '')
      res.status = 201
      json(res, ok: true)
    when 'DELETE'
      return error(res, 404, 'not found') unless File.file?(full)
      File.delete(full)
      json(res, ok: true)
    end
  end

  def self.safe_path(rel)
    target = File.expand_path(rel.empty? ? NOTES_DIR : File.join(NOTES_DIR, rel))
    target if target == NOTES_DIR || target.start_with?("#{NOTES_DIR}/")
  end

  def self.list(dir)
    Dir.children(dir)
       .reject { |e| e.start_with?('.') }
       .sort_by { |e| [File.directory?(File.join(dir, e)) ? 0 : 1, e.downcase] }
       .map do |name|
         full = File.join(dir, name)
         { name: name, path: full.delete_prefix("#{NOTES_DIR}/"), dir: File.directory?(full) }
       end
  end

  def self.json(res, data)
    res.content_type = 'application/json'
    res.body = data.to_json
  end

  def self.error(res, status, msg)
    res.status = status
    json(res, error: msg)
  end
end
