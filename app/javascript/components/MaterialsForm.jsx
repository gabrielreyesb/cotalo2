import React from 'react';
import { Form, Input, Button, Space, InputNumber } from 'antd';
import { MinusCircleOutlined, PlusOutlined } from '@ant-design/icons';

const MaterialsForm = ({ form }) => {
  return (
    <Form.List name="materials">
      {(fields, { add, remove }) => (
        <>
          {fields.map(({ key, name, ...restField }) => (
            <Space key={key} style={{ display: 'flex', marginBottom: 8 }} align="baseline">
              <Form.Item
                {...restField}
                name={[name, 'name']}
                rules={[{ required: true, message: 'Material name is required' }]}
              >
                <Input placeholder="Material Name" />
              </Form.Item>
              
              <Form.Item
                {...restField}
                name={[name, 'quantity']}
                rules={[
                  { required: true, message: 'Quantity is required' },
                  { type: 'number', min: 1, message: 'Quantity must be greater than 0' }
                ]}
              >
                <InputNumber placeholder="Quantity" min={1} />
              </Form.Item>
              
              <Form.Item
                {...restField}
                name={[name, 'unit']}
                rules={[{ required: true, message: 'Unit is required' }]}
              >
                <Input placeholder="Unit (e.g., kg, m, pcs)" />
              </Form.Item>
              
              <MinusCircleOutlined onClick={() => remove(name)} />
            </Space>
          ))}
          
          <Form.Item>
            <Button
              type="dashed"
              onClick={() => add()}
              block
              icon={<PlusOutlined />}
            >
              Add Material
            </Button>
          </Form.Item>
        </>
      )}
    </Form.List>
  );
};

export default MaterialsForm; 