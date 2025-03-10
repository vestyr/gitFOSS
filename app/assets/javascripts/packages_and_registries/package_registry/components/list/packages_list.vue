<script>
import { GlPagination, GlModal, GlSprintf } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import PackagesListRow from '~/packages/shared/components/package_list_row.vue';
import PackagesListLoader from '~/packages/shared/components/packages_list_loader.vue';
import { TrackingActions } from '~/packages/shared/constants';
import { packageTypeToTrackCategory } from '~/packages/shared/utils';
import Tracking from '~/tracking';

export default {
  components: {
    GlPagination,
    GlModal,
    GlSprintf,
    PackagesListLoader,
    PackagesListRow,
  },
  mixins: [Tracking.mixin()],
  data() {
    return {
      itemToBeDeleted: null,
    };
  },
  computed: {
    ...mapState({
      perPage: (state) => state.pagination.perPage,
      totalItems: (state) => state.pagination.total,
      page: (state) => state.pagination.page,
      isGroupPage: (state) => state.config.isGroupPage,
      isLoading: 'isLoading',
    }),
    ...mapGetters({ list: 'getList' }),
    currentPage: {
      get() {
        return this.page;
      },
      set(value) {
        this.$emit('page:changed', value);
      },
    },
    isListEmpty() {
      return !this.list || this.list.length === 0;
    },
    modalAction() {
      return s__('PackageRegistry|Delete package');
    },
    deletePackageName() {
      return this.itemToBeDeleted?.name ?? '';
    },
    tracking() {
      const category = this.itemToBeDeleted
        ? packageTypeToTrackCategory(this.itemToBeDeleted.package_type)
        : undefined;
      return {
        category,
      };
    },
  },
  methods: {
    setItemToBeDeleted(item) {
      this.itemToBeDeleted = { ...item };
      this.track(TrackingActions.REQUEST_DELETE_PACKAGE);
      this.$refs.packageListDeleteModal.show();
    },
    deleteItemConfirmation() {
      this.$emit('package:delete', this.itemToBeDeleted);
      this.track(TrackingActions.DELETE_PACKAGE);
      this.itemToBeDeleted = null;
    },
    deleteItemCanceled() {
      this.track(TrackingActions.CANCEL_DELETE_PACKAGE);
      this.itemToBeDeleted = null;
    },
  },
  i18n: {
    deleteModalContent: s__(
      'PackageRegistry|You are about to delete %{name}, this operation is irreversible, are you sure?',
    ),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <slot v-if="isListEmpty && !isLoading" name="empty-state"></slot>

    <div v-else-if="isLoading">
      <packages-list-loader />
    </div>

    <template v-else>
      <div data-qa-selector="packages-table">
        <packages-list-row
          v-for="packageEntity in list"
          :key="packageEntity.id"
          :package-entity="packageEntity"
          :package-link="packageEntity._links.web_path"
          :is-group="isGroupPage"
          @packageToDelete="setItemToBeDeleted"
        />
      </div>

      <gl-pagination
        v-model="currentPage"
        :per-page="perPage"
        :total-items="totalItems"
        align="center"
        class="gl-w-full gl-mt-3"
      />

      <gl-modal
        ref="packageListDeleteModal"
        modal-id="confirm-delete-pacakge"
        ok-variant="danger"
        @ok="deleteItemConfirmation"
        @cancel="deleteItemCanceled"
      >
        <template #modal-title>{{ modalAction }}</template>
        <template #modal-ok>{{ modalAction }}</template>
        <gl-sprintf :message="$options.i18n.deleteModalContent">
          <template #name>
            <strong>{{ deletePackageName }}</strong>
          </template>
        </gl-sprintf>
      </gl-modal>
    </template>
  </div>
</template>
