local helpers = require "spec.helpers"
local json = require "cjson"

for _, strategy in helpers.each_strategy("postgres") do
  describe("ndfd-xml-as-json plugin", function()

    local proxy_client
    local admin_client
    local bp = helpers.get_db_utils(strategy)

    setup(function()
      local service = bp.services:insert {
        name = "test-service",
        protocol = "https",
        port = 443,
        host = "mockbin.com",
        path = "/bin/c209eeb6-af56-44bf-95b5-62b9486ae800"
      }

      bp.routes:insert({
        paths = { "/ndfd" },
        service = { id = service.id }
      })

      bp.plugins:insert({
        name = "ndfd-xml-as-json",
        service_id = service.id
      })

      -- start Kong with your testing Kong configuration (defined in "spec.helpers")
      assert(helpers.start_kong( { plugins = "bundled,ndfd-xml-as-json" }))

      admin_client = helpers.admin_client()
    end)

    teardown(function()
      if admin_client then
        admin_client:close()
      end

      helpers.stop_kong()
    end)

    before_each(function()
      proxy_client = helpers.proxy_client()
    end)

    after_each(function()
      if proxy_client then
        proxy_client:close()
      end
    end)

    describe("API responses", function()
      it("should respond", function()
        local res = proxy_client:get("/ndfd", {
          body = {
            latitude = 38.99,
            longitude = -77.01
          },
          headers = {
            ["Content-Type"] = "application/json"
          },
        })

        local body = assert.res_status(200, res)

        -- ngx.log(ngx.WARN, "Response body: " .. body)
        -- os.execute("sleep " .. tonumber(300))

        local data = json.decode(body)
        assert.is.equal('temperature', data.name)
      end)
    end)
  end)
end
