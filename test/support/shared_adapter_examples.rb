# Shared tests for Gecko::Record Adapters
# requires definition of several variables
# - adapter
# - plural_name
# - record_class

require 'json'
module SharedAdapterExamples
  def test_adapter_all
    VCR.use_cassette(plural_name) do
      collection = adapter.where(limit: 5)
      assert_instance_of(Array, collection)
      assert_equal(5, collection.size)
      assert_instance_of(record_class, collection[0])
    end
  end

  def test_adapter_count
    VCR.use_cassette(plural_name + "_count") do
      assert(adapter.count > 10)
    end
  end

  def test_adapter_uses_identity_map
    VCR.use_cassette(plural_name) do
      collection = adapter.where(limit: 5)
      assert_equal(collection.first, adapter.find(collection.first.id))
    end
  end

  def test_record_for_id
    mock_record = Object.new
    adapter.instance_variable_set(:@identity_map, {12 => mock_record})
    assert_equal(mock_record, adapter.record_for_id(12))
  end

  def test_record_for_id_miss
    ex = assert_raises Gecko::Record::RecordNotInIdentityMap do
     adapter.record_for_id(12345)
    end
    assert_equal("Couldn't find #{record_class.name} with id=12345", ex.message)
  end

  def test_has_record_for_id
    mock_record = Object.new
    adapter.instance_variable_set(:@identity_map, {12 => mock_record})
    assert adapter.has_record_for_id?(12)
    assert !adapter.has_record_for_id?(12345)
  end

  def test_fetch
    request_stub = stub_request(:get, /#{plural_name}\/\d+/)
      .to_return({
        headers: {"Content-Type" => "application/json"},
        body:    JSON.dump({plural_name.singularize => {id: 12345}})
      })
    record = adapter.fetch(12345)
    assert_equal(12345, record.id)
    assert_requested(request_stub)
  end

  def test_fetch_miss
    request_stub = stub_request(:get, /#{plural_name}\/\d+/)
      .to_return({
        status:  404,
        headers: {"Content-Type" => "application/json"},
        body: JSON.dump({
          type: "Not Found",
          message: "Couldn't find #{plural_name.singularize} with id 12345"
        })
      })
    exception = assert_raises Gecko::Record::RecordNotFound do
      adapter.fetch(12345)
    end

    assert_equal("Couldn't find #{record_class.name} with id=12345", exception.message)
  end

  def test_find_without_id
    exception = assert_raises Gecko::Record::RecordNotFound do
      adapter.find(nil)
    end

    assert_equal("Couldn't find #{record_class.name} without an ID", exception.message)
  end

  def test_build
    record = adapter.build
    assert_instance_of(record_class, record)
    assert !record.persisted?
  end

  def test_build_with_attributes
    record = adapter.build(random_attribute => "Max Power")
    assert_equal(record.attributes[random_attribute], "Max Power")
    assert !record.persisted?
  end

  def test_saving_new_record
    record = adapter.build
    mock_api_request(record,
      [:post, plural_name],
      [200, {plural_name.singularize => {id: 123}}]
    )
    adapter.save(record)
    assert_equal(record.id, 123)
    assert(record.valid?)
  end

  def test_saving_invalid_record
    record = adapter.build
    mock_api_request(record,
      [:post, plural_name],
      [422, {"errors" => {title: ["can not be bounced"]}}]
    )
    adapter.save(record)
    assert_nil(record.id)
    assert(!record.valid?)
  end

  def test_saving_existing_record
    record = adapter.build(id: 123)
    mock_api_request(record,
      [:put, "#{plural_name}/#{record.id}"],
      [204, {}]
    )
    adapter.save(record)
    assert(record.valid?)
  end

  def test_saving_existing_invalid_record
    record = adapter.build(id: 123)
    mock_api_request(record,
      [:put, "#{plural_name}/#{record.id}"],
      [422, {"errors" => {title: ["can not be bounced"]}}]
    )
    adapter.save(record)
    assert(!record.valid?)
    assert(record.errors[:title].any?)
  end

private
  def mock_api_request(record, request, response)
    mock_token = mock
    mock_response = mock(status: response[0], parsed: response[1])
    mock_token.expects(:request)
              .with(request[0], request[1], body: record.as_json, raise_errors: false)
              .returns(mock_response)
    adapter.client.access_token = mock_token
  end

  def random_attribute
    @rattr ||= record_class.attribute_set.find { |att| att.type == Axiom::Types::String }.name
  end
end
