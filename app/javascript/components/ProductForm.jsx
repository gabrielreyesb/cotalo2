import React, { useState } from 'react';
import { Form, Input, Button, Space, InputNumber, message } from 'antd';
import MaterialsForm from './MaterialsForm';

const ProductForm = ({ onSubmit, initialData = null }) => {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);

  const validateForm = (values) => {
    const errors = [];

    // Validate description
    if (!values.description?.trim()) {
      errors.push('Description is required');
    }

    // Validate general info
    const generalInfo = values.general_info || {};
    if (!generalInfo.quantity || generalInfo.quantity <= 0) {
      errors.push('Product quantity must be greater than 0');
    }
    if (!generalInfo.width || generalInfo.width <= 0) {
      errors.push('Product width must be greater than 0');
    }
    if (!generalInfo.length || generalInfo.length <= 0) {
      errors.push('Product length must be greater than 0');
    }

    // Validate materials
    if (!values.materials || values.materials.length === 0) {
      errors.push('At least one material is required');
    } else {
      values.materials.forEach((material, index) => {
        if (!material.name?.trim()) {
          errors.push(`Material ${index + 1}: Name is required`);
        }
        if (!material.quantity || material.quantity <= 0) {
          errors.push(`Material ${index + 1}: Quantity must be greater than 0`);
        }
        if (!material.unit?.trim()) {
          errors.push(`Material ${index + 1}: Unit is required`);
        }
      });
    }

    return errors;
  };

  const handleSubmit = async (values) => {
    try {
      setLoading(true);
      
      // Validate form
      const validationErrors = validateForm(values);
      if (validationErrors.length > 0) {
        validationErrors.forEach(error => message.error(error));
        return;
      }

      // Clean up values before submission
      const cleanedValues = {
        ...values,
        description: values.description.trim(),
        materials: values.materials?.map(material => ({
          ...material,
          name: material.name.trim(),
          unit: material.unit.trim()
        }))
      };
      
      await onSubmit(cleanedValues);
      message.success('Product saved successfully');
      form.resetFields();
    } catch (error) {
      console.error('Error saving product:', error);
      message.error(error.message || 'Failed to save product. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Form
      form={form}
      layout="vertical"
      onFinish={handleSubmit}
      initialValues={initialData}
      scrollToFirstError
    >
      <Form.Item
        name="description"
        label="Description"
        rules={[{ required: true, whitespace: true, message: 'Please enter a description' }]}
      >
        <Input.TextArea rows={4} />
      </Form.Item>

      <Form.Item label="General Information">
        <Space direction="vertical" style={{ width: '100%' }}>
          <Form.Item
            name={['general_info', 'quantity']}
            label="Quantity"
            rules={[
              { required: true, message: 'Please enter quantity' },
              { type: 'number', min: 1, message: 'Quantity must be greater than 0' }
            ]}
          >
            <InputNumber min={1} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            name={['general_info', 'width']}
            label="Width (cm)"
            rules={[
              { required: true, message: 'Please enter width' },
              { type: 'number', min: 0.1, message: 'Width must be greater than 0' }
            ]}
          >
            <InputNumber min={0.1} step={0.1} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            name={['general_info', 'length']}
            label="Length (cm)"
            rules={[
              { required: true, message: 'Please enter length' },
              { type: 'number', min: 0.1, message: 'Length must be greater than 0' }
            ]}
          >
            <InputNumber min={0.1} step={0.1} style={{ width: '100%' }} />
          </Form.Item>
        </Space>
      </Form.Item>

      <Form.Item
        label="Materials"
        required
        tooltip="At least one material is required"
      >
        <MaterialsForm form={form} />
      </Form.Item>

      <Form.Item>
        <Button type="primary" htmlType="submit" loading={loading} block>
          Save Product
        </Button>
      </Form.Item>
    </Form>
  );
};

export default ProductForm; 