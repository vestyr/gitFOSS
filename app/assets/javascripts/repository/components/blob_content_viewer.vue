<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import getRefMixin from '../mixins/get_ref';
import blobInfoQuery from '../queries/blob_info.query.graphql';
import BlobButtonGroup from './blob_button_group.vue';
import BlobEdit from './blob_edit.vue';
import { loadViewer, viewerProps } from './blob_viewers';

export default {
  components: {
    BlobHeader,
    BlobEdit,
    BlobButtonGroup,
    BlobContent,
    GlLoadingIcon,
  },
  mixins: [getRefMixin],
  inject: {
    originalBranch: {
      default: '',
    },
  },
  apollo: {
    project: {
      query: blobInfoQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.path,
          ref: this.originalBranch || this.ref,
        };
      },
      result() {
        this.switchViewer(
          this.hasRichViewer && !window.location.hash ? RICH_BLOB_VIEWER : SIMPLE_BLOB_VIEWER,
        );
      },
      error() {
        this.displayError();
      },
    },
  },
  provide() {
    return {
      blobHash: uniqueId(),
    };
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      legacyRichViewer: null,
      legacySimpleViewer: null,
      isBinary: false,
      isLoadingLegacyViewer: false,
      activeViewerType: SIMPLE_BLOB_VIEWER,
      project: {
        userPermissions: {
          pushCode: false,
          downloadCode: false,
        },
        pathLocks: {
          nodes: [],
        },
        repository: {
          empty: true,
          blobs: {
            nodes: [
              {
                name: '',
                size: '',
                rawTextBlob: '',
                type: '',
                fileType: '',
                tooLarge: false,
                path: '',
                editBlobPath: '',
                ideEditPath: '',
                storedExternally: false,
                rawPath: '',
                externalStorageUrl: '',
                replacePath: '',
                deletePath: '',
                forkPath: '',
                simpleViewer: {},
                richViewer: null,
                webPath: '',
              },
            ],
          },
        },
      },
    };
  },
  computed: {
    isLoggedIn() {
      return isLoggedIn();
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
    isBinaryFileType() {
      return this.isBinary || this.blobInfo.simpleViewer?.fileType !== 'text';
    },
    blobInfo() {
      const nodes = this.project?.repository?.blobs?.nodes || [];

      return nodes[0] || {};
    },
    viewer() {
      const { richViewer, simpleViewer } = this.blobInfo;
      return this.activeViewerType === RICH_BLOB_VIEWER ? richViewer : simpleViewer;
    },
    hasRichViewer() {
      return Boolean(this.blobInfo.richViewer);
    },
    hasRenderError() {
      return Boolean(this.viewer.renderError);
    },
    blobViewer() {
      const { fileType } = this.viewer;
      return loadViewer(fileType);
    },
    viewerProps() {
      const { fileType } = this.viewer;
      return viewerProps(fileType, this.blobInfo);
    },
    canLock() {
      const { pushCode, downloadCode } = this.project.userPermissions;

      return pushCode && downloadCode;
    },
    isLocked() {
      return this.project.pathLocks.nodes.some((node) => node.path === this.path);
    },
  },
  methods: {
    loadLegacyViewer(type) {
      if (this.legacyViewerLoaded(type)) {
        return;
      }

      this.isLoadingLegacyViewer = true;
      axios
        .get(`${this.blobInfo.webPath}?format=json&viewer=${type}`)
        .then(({ data: { html, binary } }) => {
          if (type === 'simple') {
            this.legacySimpleViewer = html;
          } else {
            this.legacyRichViewer = html;
          }

          this.isBinary = binary;
          this.isLoadingLegacyViewer = false;
        })
        .catch(() => this.displayError());
    },
    legacyViewerLoaded(type) {
      return (
        (type === SIMPLE_BLOB_VIEWER && this.legacySimpleViewer) ||
        (type === RICH_BLOB_VIEWER && this.legacyRichViewer)
      );
    },
    displayError() {
      createFlash({ message: __('An error occurred while loading the file. Please try again.') });
    },
    switchViewer(newViewer) {
      this.activeViewerType = newViewer || SIMPLE_BLOB_VIEWER;

      if (!this.blobViewer) {
        this.loadLegacyViewer(this.activeViewerType);
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="sm" />
    <div v-if="blobInfo && !isLoading" class="file-holder">
      <blob-header
        :blob="blobInfo"
        :hide-viewer-switcher="!hasRichViewer || isBinaryFileType"
        :is-binary="isBinaryFileType"
        :active-viewer-type="viewer.type"
        :has-render-error="hasRenderError"
        @viewer-changed="switchViewer"
      >
        <template #actions>
          <blob-edit
            :show-edit-button="!isBinaryFileType"
            :edit-path="blobInfo.editBlobPath"
            :web-ide-path="blobInfo.ideEditPath"
          />
          <blob-button-group
            v-if="isLoggedIn"
            :path="path"
            :name="blobInfo.name"
            :replace-path="blobInfo.replacePath"
            :delete-path="blobInfo.webPath"
            :can-push-code="project.userPermissions.pushCode"
            :empty-repo="project.repository.empty"
            :project-path="projectPath"
            :is-locked="isLocked"
            :can-lock="canLock"
          />
        </template>
      </blob-header>
      <blob-content
        v-if="!blobViewer"
        :rich-viewer="legacyRichViewer"
        :blob="blobInfo"
        :content="legacySimpleViewer"
        :is-raw-content="true"
        :active-viewer="viewer"
        :hide-line-numbers="true"
        :loading="isLoadingLegacyViewer"
      />
      <component :is="blobViewer" v-else v-bind="viewerProps" class="blob-viewer" />
    </div>
  </div>
</template>
