<script>
import {
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlFormInput,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import ImportGroupDropdown from '../../components/group_dropdown.vue';
import {
  isInvalid,
  getInvalidNameValidationMessage,
  isNameValid,
  isAvailableForImport,
} from '../utils';

export default {
  components: {
    ImportGroupDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlFormInput,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    availableNamespaces: {
      type: Array,
      required: true,
    },
    groupPathRegex: {
      type: RegExp,
      required: true,
    },
    groupUrlErrorMessage: {
      type: String,
      required: true,
    },
  },

  computed: {
    availableNamespaceNames() {
      return this.availableNamespaces.map((ns) => ns.full_path);
    },

    importTarget() {
      return this.group.import_target;
    },

    invalidNameValidationMessage() {
      return getInvalidNameValidationMessage(this.group);
    },

    isInvalid() {
      return isInvalid(this.group, this.groupPathRegex);
    },

    isNameValid() {
      return isNameValid(this.group, this.groupPathRegex);
    },

    isAvailableForImport() {
      return isAvailableForImport(this.group);
    },
  },

  i18n: {
    NAME_ALREADY_EXISTS: s__('BulkImport|Name already exists.'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-stretch">
    <import-group-dropdown
      #default="{ namespaces }"
      :text="importTarget.target_namespace"
      :disabled="!isAvailableForImport"
      :namespaces="availableNamespaceNames"
      toggle-class="gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
      class="gl-h-7 gl-flex-grow-1"
      data-qa-selector="target_namespace_selector_dropdown"
    >
      <gl-dropdown-item @click="$emit('update-target-namespace', '')">{{
        s__('BulkImport|No parent')
      }}</gl-dropdown-item>
      <template v-if="namespaces.length">
        <gl-dropdown-divider />
        <gl-dropdown-section-header>
          {{ s__('BulkImport|Existing groups') }}
        </gl-dropdown-section-header>
        <gl-dropdown-item
          v-for="ns in namespaces"
          :key="ns"
          data-qa-selector="target_group_dropdown_item"
          :data-qa-group-name="ns"
          @click="$emit('update-target-namespace', ns)"
        >
          {{ ns }}
        </gl-dropdown-item>
      </template>
    </import-group-dropdown>
    <div
      class="gl-h-7 gl-px-3 gl-display-flex gl-align-items-center gl-border-solid gl-border-0 gl-border-t-1 gl-border-b-1 gl-bg-gray-10"
      :class="{
        'gl-text-gray-400 gl-border-gray-100': !isAvailableForImport,
        'gl-border-gray-200': isAvailableForImport,
      }"
    >
      /
    </div>
    <div class="gl-flex-grow-1">
      <gl-form-input
        class="gl-rounded-top-left-none gl-rounded-bottom-left-none"
        :class="{
          'gl-inset-border-1-gray-200!': isAvailableForImport,
          'gl-inset-border-1-gray-100!': !isAvailableForImport,
          'is-invalid': isInvalid && isAvailableForImport,
        }"
        :disabled="!isAvailableForImport"
        :value="importTarget.new_name"
        @input="$emit('update-new-name', $event)"
      />
      <p v-if="isInvalid" class="gl-text-red-500 gl-m-0 gl-mt-2">
        <template v-if="!isNameValid">
          {{ groupUrlErrorMessage }}
        </template>
        <template v-else-if="invalidNameValidationMessage">
          {{ invalidNameValidationMessage }}
        </template>
      </p>
    </div>
  </div>
</template>
